defmodule Tai.Orders.Worker do
  use GenServer

  alias Tai.Orders.{
    Order,
    OrderStore,
    OrderSubmissions,
    Responses,
    Transition,
    Transitions
  }

  defmodule State do
    defstruct ~w[tasks]a
  end

  defmodule Provider do
    alias Tai.Orders.OrderStore

    defdelegate update(transition), to: OrderStore
  end

  @type submission :: OrderSubmissions.Factory.submission()
  @type order :: Order.t()
  @type status :: Tai.Orders.Order.status()
  @type status_required :: status | [status]
  @type transition :: Transition.t()
  @type create_response :: {:ok, order}
  @type cancel_error_reason :: {:invalid_status, was :: status, status_required, transition}
  @type cancel_response :: {:ok, updated :: order} | {:error, cancel_error_reason}
  @type amend_attrs :: %{
          optional(:price) => Decimal.t(),
          optional(:qty) => Decimal.t()
        }
  @type amend_response ::
          {:ok, updated :: order}
          | {:error, {:invalid_status, was :: status, status_required, transition}}
  @type amend_bulk_reject_reason :: {:invalid_status, was :: status, status_required, transition}
  @type amend_bulk_response :: [{:ok, updated :: order} | {:error, amend_bulk_reject_reason}]

  def start_link(_) do
    state = %State{tasks: %{}}
    GenServer.start_link(__MODULE__, state)
  end

  @spec create(pid, submission) :: create_response
  def create(pid, submission) do
    GenServer.call(pid, {:create, submission})
  end

  @spec cancel(pid, order, module) :: create_response
  def cancel(pid, order, provider \\ Provider) do
    GenServer.call(pid, {:cancel, order, provider})
  end

  @spec amend(pid, order, amend_attrs, module) :: amend_response
  def amend(pid, order, attrs, provider \\ Provider) do
    GenServer.call(pid, {:amend, order, attrs, provider})
  end

  @spec amend_bulk(pid, [{order, amend_attrs}], module) :: amend_response
  def amend_bulk(pid, amend_set, provider \\ Provider) do
    GenServer.call(pid, {:amend_bulk, amend_set, provider})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:create, submission}, _from, state) do
    {:ok, order} = OrderStore.enqueue(submission)
    notify_initial_updated_order(order)

    task =
      Task.async(fn ->
        if Tai.Settings.send_orders?() do
          try do
            order
            |> send_create_to_venue()
            |> parse_create_response()
            |> notify_create_updated_order()
          rescue
            e ->
              {e, __STACKTRACE__}
              |> rescue_create_venue_adapter_error(order)
              |> notify_create_updated_order()
          end
        else
          order.client_id
          |> skip!
          |> notify_create_updated_order()
        end
      end)

    tasks = Map.put(state.tasks, task.ref, task)
    state = %{state | tasks: tasks}
    {:reply, {:ok, order}, state}
  end

  @impl true
  def handle_call({:cancel, order, provider}, _from, state) do
    with transition <- %Transitions.PendCancel{client_id: order.client_id},
         {:ok, {old, updated}} <- provider.update(transition) do
      Tai.Orders.Services.NotifyUpdate.notify!(old, updated)

      task =
        Task.async(fn ->
          try do
            updated
            |> send_cancel_to_venue()
            |> parse_cancel_response(provider)
            |> notify_cancel_updated_order()
          rescue
            e ->
              {e, __STACKTRACE__}
              |> rescue_cancel_venue_adapter_error(updated, provider)
              |> notify_cancel_updated_order()
          end
        end)

      tasks = Map.put(state.tasks, task.ref, task)
      state = %{state | tasks: tasks}
      {:reply, {:ok, updated}, state}
    else
      {:error, {:invalid_status, was, required, transition}} = error ->
        warn_invalid_status(was, required, transition)
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:amend, order, attrs, provider}, _from, state) do
    with transition <- %Transitions.PendAmend{client_id: order.client_id},
         {:ok, {old, updated}} <- provider.update(transition) do
      Tai.Orders.Services.NotifyUpdate.notify!(old, updated)

      task =
        Task.async(fn ->
          try do
            updated
            |> send_amend_order(attrs)
            |> parse_amend_response(provider)
            |> notify_amend_updated_order()
          rescue
            e ->
              {e, __STACKTRACE__}
              |> rescue_venue_adapter_error(updated, provider)
              |> notify_amend_updated_order()
          end
        end)

      tasks = Map.put(state.tasks, task.ref, task)
      state = %{state | tasks: tasks}
      {:reply, {:ok, updated}, state}
    else
      {:error, {:invalid_status, was, required, transition}} = error ->
        warn_invalid_status(was, required, transition)
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:amend_bulk, amend_set, provider}, _from, state) do
    pending_orders = amend_set |> Enum.map(&market_order_pend_amend(&1, provider))

    task =
      Task.async(fn ->
        try do
          pending_orders
          |> Enum.reduce([], fn
            {:ok, pending_order}, acc ->
              {_, order_attributes} =
                Enum.find(amend_set, fn {order, _} ->
                  order.client_id == pending_order.client_id
                end)

              [{pending_order, order_attributes} | acc]

            {:error, _}, acc ->
              acc
          end)
          |> send_amend_bulk_orders()
          |> parse_amend_bulk_response(amend_set, provider)
          |> Enum.map(&notify_amend_bulk_updated_order/1)
        rescue
          e ->
            {e, __STACKTRACE__}
            |> rescue_amend_bulk_venue_adapter_error(amend_set, provider)
            |> Enum.map(&notify_amend_bulk_updated_order/1)
        end
      end)

    tasks = Map.put(state.tasks, task.ref, task)
    state = %{state | tasks: tasks}
    {:reply, pending_orders, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    tasks = Map.delete(state.tasks, ref)
    state = %{state | tasks: tasks}
    {:noreply, state}
  end

  @impl true
  def handle_info({_ref, _result}, state) do
    {:noreply, state}
  end

  defp warn_invalid_status(was, required, %transition_name{} = transition) do
    last_received_at = Map.get(transition, :last_received_at)

    TaiEvents.warn(%Tai.Events.OrderUpdateInvalidStatus{
      was: was,
      required: required,
      client_id: transition.client_id,
      transition: transition_name,
      last_received_at: last_received_at && Tai.Time.monotonic_to_date_time!(last_received_at),
      last_venue_timestamp: transition |> Map.get(:last_venue_timestamp)
    })
  end

  ###################
  # create order
  ###################
  defp notify_initial_updated_order(order) do
    Tai.Orders.Services.NotifyUpdate.notify!(nil, order)
  end

  defp send_create_to_venue(order) do
    result = Tai.Venues.Client.create_order(order)
    {result, order}
  end

  defp parse_create_response({
         {:ok, %Responses.CreateAccepted{} = response},
         order
       }) do
    %Transitions.AcceptCreate{
      client_id: order.client_id,
      venue_order_id: response.id,
      last_received_at: response.received_at,
      last_venue_timestamp: response.venue_timestamp
    }
    |> OrderStore.update()
  end

  defp parse_create_response({
         {:ok, %Responses.Create{status: :open} = response},
         order
       }) do
    %Transitions.Open{
      client_id: order.client_id,
      venue_order_id: response.id,
      cumulative_qty: response.cumulative_qty,
      leaves_qty: response.leaves_qty,
      last_received_at: response.received_at,
      last_venue_timestamp: response.venue_timestamp
    }
    |> OrderStore.update()
  end

  defp parse_create_response({
         {:ok, %Responses.Create{status: :filled} = response},
         order
       }) do
    %Transitions.Fill{
      client_id: order.client_id,
      venue_order_id: response.id,
      cumulative_qty: response.cumulative_qty,
      last_received_at: response.received_at,
      last_venue_timestamp: response.venue_timestamp
    }
    |> OrderStore.update()
  end

  defp parse_create_response({
         {:ok, %Responses.Create{status: :expired} = response},
         order
       }) do
    %Transitions.Expire{
      client_id: order.client_id,
      venue_order_id: response.id,
      cumulative_qty: response.cumulative_qty,
      leaves_qty: response.leaves_qty,
      last_received_at: response.received_at,
      last_venue_timestamp: response.venue_timestamp
    }
    |> OrderStore.update()
  end

  defp parse_create_response({
         {:ok, %Responses.Create{status: :rejected} = response},
         order
       }) do
    %Transitions.Reject{
      client_id: order.client_id,
      venue_order_id: response.id,
      last_received_at: response.received_at,
      last_venue_timestamp: response.venue_timestamp
    }
    |> OrderStore.update()
  end

  defp parse_create_response({{:error, reason}, order}) do
    %Transitions.CreateError{
      client_id: order.client_id,
      reason: reason,
      last_received_at: Tai.Time.monotonic_time()
    }
    |> OrderStore.update()
  end

  defp rescue_create_venue_adapter_error(reason, order) do
    %Transitions.CreateError{
      client_id: order.client_id,
      reason: {:unhandled, reason},
      last_received_at: Tai.Time.monotonic_time()
    }
    |> OrderStore.update()
  end

  defp skip!(client_id) do
    %Transitions.Skip{
      client_id: client_id
    }
    |> OrderStore.update()
  end

  defp notify_create_updated_order({:ok, {prev, current}}) do
    Tai.Orders.Services.NotifyUpdate.notify!(prev, current)
  end

  defp notify_create_updated_order({:error, {:invalid_status, _, _, %transition_name{}}})
       when transition_name == Transitions.AcceptCreate do
    :ok
  end

  ###################
  # cancel order
  ###################
  defp send_cancel_to_venue(order) do
    {order, Tai.Venues.Client.cancel_order(order)}
  end

  defp parse_cancel_response({order, {:ok, %Responses.Cancel{} = response}}, provider) do
    %Transitions.Cancel{
      client_id: order.client_id,
      last_received_at: Tai.Time.monotonic_time(),
      last_venue_timestamp: response.venue_timestamp
    }
    |> provider.update()
  end

  defp parse_cancel_response({order, {:ok, %Responses.CancelAccepted{} = response}}, provider) do
    %Transitions.AcceptCancel{
      client_id: order.client_id,
      last_received_at: Tai.Time.monotonic_time(),
      last_venue_timestamp: response.venue_timestamp
    }
    |> provider.update()
  end

  defp parse_cancel_response({order, {:error, reason}}, provider) do
    %Transitions.CancelError{
      client_id: order.client_id,
      reason: reason,
      last_received_at: Tai.Time.monotonic_time()
    }
    |> provider.update()
  end

  defp rescue_cancel_venue_adapter_error(reason, order, provider) do
    %Transitions.CancelError{
      client_id: order.client_id,
      reason: {:unhandled, reason},
      last_received_at: Tai.Time.monotonic_time()
    }
    |> provider.update()
  end

  defp notify_cancel_updated_order({:ok, {previous_order, order}}) do
    Tai.Orders.Services.NotifyUpdate.notify!(previous_order, order)
  end

  defp notify_cancel_updated_order({:error, {:invalid_status, _, _, %transition_name{}}})
       when transition_name == Transitions.AcceptCancel do
    :ok
  end

  defp notify_cancel_updated_order({:error, {:invalid_status, was, required, transition}}) do
    warn_invalid_status(was, required, transition)
  end

  ###################
  # amend order
  ###################
  def send_amend_order(order, attrs) do
    {order, Tai.Venues.Client.amend_order(order, attrs)}
  end

  defp parse_amend_response({order, {:ok, amend_response}}, provider) do
    %Transitions.Amend{
      client_id: order.client_id,
      price: amend_response.price,
      leaves_qty: amend_response.leaves_qty,
      last_received_at: Tai.Time.monotonic_time(),
      last_venue_timestamp: amend_response.venue_timestamp
    }
    |> provider.update()
  end

  defp parse_amend_response({order, {:error, reason}}, provider) do
    %Transitions.AmendError{
      client_id: order.client_id,
      reason: reason,
      last_received_at: Tai.Time.monotonic_time()
    }
    |> provider.update()
  end

  defp rescue_venue_adapter_error(reason, order, provider) do
    %Transitions.AmendError{
      client_id: order.client_id,
      reason: {:unhandled, reason},
      last_received_at: Tai.Time.monotonic_time()
    }
    |> provider.update()
  end

  defp notify_amend_updated_order({:ok, {old, updated}}) do
    Tai.Orders.Services.NotifyUpdate.notify!(old, updated)
    updated
  end

  defp notify_amend_updated_order({:error, {:invalid_status, was, required, transition}}) do
    warn_invalid_status(was, required, transition)
  end

  ###################
  # amend bulk order
  ###################
  defdelegate send_amend_bulk_orders(orders), to: Tai.Venues.Client, as: :amend_bulk_orders

  defp parse_amend_bulk_response(
         {:ok, %{orders: amend_responses}},
         orders_and_attributes,
         provider
       ) do
    amend_responses
    |> Enum.map(fn amend_response ->
      order =
        Enum.find(orders_and_attributes, fn {order, _} ->
          order.venue_order_id == amend_response.id
        end)
        |> elem(0)

      %Transitions.Amend{
        client_id: order.client_id,
        price: amend_response.price,
        leaves_qty: amend_response.leaves_qty,
        last_received_at: Tai.Time.monotonic_time(),
        last_venue_timestamp: amend_response.venue_timestamp
      }
      |> provider.update()
    end)
  end

  defp parse_amend_bulk_response({:error, reason}, orders_and_attributes, provider) do
    orders_and_attributes
    |> Enum.map(fn {order, _} ->
      %Transitions.AmendError{
        client_id: order.client_id,
        reason: reason,
        last_received_at: Tai.Time.monotonic_time()
      }
      |> provider.update()
    end)
  end

  defp rescue_amend_bulk_venue_adapter_error(reason, orders_and_attributes, provider) do
    orders_and_attributes
    |> Enum.map(fn {order, _} ->
      %Transitions.AmendError{
        client_id: order.client_id,
        reason: reason,
        last_received_at: Tai.Time.monotonic_time()
      }
      |> provider.update()
    end)
  end

  defp notify_amend_bulk_updated_order({:ok, {old, updated}}) do
    Tai.Orders.Services.NotifyUpdate.notify!(old, updated)
    updated
  end

  defp market_order_pend_amend({order, _}, provider) do
    with transition <- %Transitions.PendAmend{client_id: order.client_id},
         {:ok, {old, updated}} <- provider.update(transition) do
      Tai.Orders.Services.NotifyUpdate.notify!(old, updated)
      {:ok, updated}
    else
      {:error, {:invalid_status, was, required, transition}} = error ->
        warn_invalid_status(was, required, transition)
        error
    end
  end
end
