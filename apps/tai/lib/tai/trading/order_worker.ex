defmodule Tai.Trading.OrderWorker do
  use GenServer

  alias Tai.Trading.OrderStore.Actions

  alias Tai.Trading.{
    NotifyOrderUpdate,
    OrderResponses,
    OrderStore,
    OrderSubmissions,
    Order
  }

  defmodule State do
    defstruct ~w[tasks]a
  end

  defmodule Provider do
    alias Tai.Trading.OrderStore

    defdelegate update(action), to: OrderStore
  end

  @type submission :: OrderSubmissions.Factory.submission()
  @type order :: Order.t()
  @type status :: Tai.Trading.Order.status()
  @type status_required :: status | [status]
  @type action :: Tai.Trading.OrderStore.Action.t()
  @type create_response :: {:ok, order}
  @type cancel_error_reason :: {:invalid_status, was :: status, status_required, action}
  @type cancel_response :: {:ok, updated :: order} | {:error, cancel_error_reason}
  @type amend_attrs :: %{
          optional(:price) => Decimal.t(),
          optional(:qty) => Decimal.t()
        }
  @type amend_response ::
          {:ok, updated :: order}
          | {:error, {:invalid_status, was :: status, status_required, action}}

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
    with action <- %OrderStore.Actions.PendCancel{client_id: order.client_id},
         {:ok, {old, updated}} <- provider.update(action) do
      NotifyOrderUpdate.notify!(old, updated)

      task = Task.async(fn ->
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
      {:error, {:invalid_status, was, required, action}} = error ->
        warn_invalid_status(was, required, action)
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:amend, order, attrs, provider}, _from, state) do
    with action <- %OrderStore.Actions.PendAmend{client_id: order.client_id},
         {:ok, {old, updated}} <- provider.update(action) do
      NotifyOrderUpdate.notify!(old, updated)

      task = Task.async(fn ->
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
      {:error, {:invalid_status, was, required, action}} = error ->
        warn_invalid_status(was, required, action)
        {:reply, error, state}
    end
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

  defp warn_invalid_status(was, required, %action_name{} = action) do
    last_received_at = Map.get(action, :last_received_at)

    TaiEvents.warn(%Tai.Events.OrderUpdateInvalidStatus{
      was: was,
      required: required,
      client_id: action.client_id,
      action: action_name,
      last_received_at: last_received_at && Tai.Time.monotonic_to_date_time!(last_received_at),
      last_venue_timestamp: action |> Map.get(:last_venue_timestamp)
    })
  end

  ###################
  # create order
  ###################
  defp notify_initial_updated_order(order) do
    NotifyOrderUpdate.notify!(nil, order)
  end

  defp send_create_to_venue(order) do
    result = Tai.Venues.Client.create_order(order)
    {result, order}
  end

  defp parse_create_response({
         {:ok, %OrderResponses.CreateAccepted{} = response},
         order
       }) do
    %Actions.AcceptCreate{
      client_id: order.client_id,
      venue_order_id: response.id,
      last_received_at: response.received_at,
      last_venue_timestamp: response.venue_timestamp
    }
    |> OrderStore.update()
  end

  defp parse_create_response({
         {:ok, %OrderResponses.Create{status: :open} = response},
         order
       }) do
    %Actions.Open{
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
         {:ok, %OrderResponses.Create{status: :filled} = response},
         order
       }) do
    %Actions.Fill{
      client_id: order.client_id,
      venue_order_id: response.id,
      cumulative_qty: response.cumulative_qty,
      last_received_at: response.received_at,
      last_venue_timestamp: response.venue_timestamp
    }
    |> OrderStore.update()
  end

  defp parse_create_response({
         {:ok, %OrderResponses.Create{status: :expired} = response},
         order
       }) do
    %Actions.Expire{
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
         {:ok, %OrderResponses.Create{status: :rejected} = response},
         order
       }) do
    %Actions.Reject{
      client_id: order.client_id,
      venue_order_id: response.id,
      last_received_at: response.received_at,
      last_venue_timestamp: response.venue_timestamp
    }
    |> OrderStore.update()
  end

  defp parse_create_response({{:error, reason}, order}) do
    %Actions.CreateError{
      client_id: order.client_id,
      reason: reason,
      last_received_at: Tai.Time.monotonic_time()
    }
    |> OrderStore.update()
  end

  defp rescue_create_venue_adapter_error(reason, order) do
    %Actions.CreateError{
      client_id: order.client_id,
      reason: {:unhandled, reason},
      last_received_at: Tai.Time.monotonic_time()
    }
    |> OrderStore.update()
  end

  defp skip!(client_id) do
    %Actions.Skip{
      client_id: client_id
    }
    |> OrderStore.update()
  end

  defp notify_create_updated_order({:ok, {prev, current}}) do
    NotifyOrderUpdate.notify!(prev, current)
  end

  defp notify_create_updated_order({:error, {:invalid_status, _, _, %action_name{}}})
       when action_name == Actions.AcceptCreate do
    :ok
  end

  ###################
  # cancel order
  ###################
  defp send_cancel_to_venue(order) do
    {order, Tai.Venues.Client.cancel_order(order)}
  end

  defp parse_cancel_response({order, {:ok, %OrderResponses.Cancel{} = response}}, provider) do
    %OrderStore.Actions.Cancel{
      client_id: order.client_id,
      last_received_at: Tai.Time.monotonic_time(),
      last_venue_timestamp: response.venue_timestamp
    }
    |> provider.update()
  end

  defp parse_cancel_response({order, {:ok, %OrderResponses.CancelAccepted{} = response}}, provider) do
    %OrderStore.Actions.AcceptCancel{
      client_id: order.client_id,
      last_received_at: Tai.Time.monotonic_time(),
      last_venue_timestamp: response.venue_timestamp
    }
    |> provider.update()
  end

  defp parse_cancel_response({order, {:error, reason}}, provider) do
    %OrderStore.Actions.CancelError{
      client_id: order.client_id,
      reason: reason,
      last_received_at: Tai.Time.monotonic_time()
    }
    |> provider.update()
  end

  defp rescue_cancel_venue_adapter_error(reason, order, provider) do
    %OrderStore.Actions.CancelError{
      client_id: order.client_id,
      reason: {:unhandled, reason},
      last_received_at: Tai.Time.monotonic_time()
    }
    |> provider.update()
  end

  defp notify_cancel_updated_order({:ok, {previous_order, order}}) do
    NotifyOrderUpdate.notify!(previous_order, order)
  end

  defp notify_cancel_updated_order({:error, {:invalid_status, _, _, %action_name{}}})
       when action_name == OrderStore.Actions.AcceptCancel do
    :ok
  end

  defp notify_cancel_updated_order({:error, {:invalid_status, was, required, action}}) do
    warn_invalid_status(was, required, action)
  end

  ###################
  # amend order
  ###################
  def send_amend_order(order, attrs) do
    {order, Tai.Venues.Client.amend_order(order, attrs)}
  end

  defp parse_amend_response({order, {:ok, amend_response}}, provider) do
    %OrderStore.Actions.Amend{
      client_id: order.client_id,
      price: amend_response.price,
      leaves_qty: amend_response.leaves_qty,
      last_received_at: Tai.Time.monotonic_time(),
      last_venue_timestamp: amend_response.venue_timestamp
    }
    |> provider.update()
  end

  defp parse_amend_response({order, {:error, reason}}, provider) do
    %OrderStore.Actions.AmendError{
      client_id: order.client_id,
      reason: reason,
      last_received_at: Tai.Time.monotonic_time()
    }
    |> provider.update()
  end

  defp rescue_venue_adapter_error(reason, order, provider) do
    %OrderStore.Actions.AmendError{
      client_id: order.client_id,
      reason: {:unhandled, reason},
      last_received_at: Tai.Time.monotonic_time()
    }
    |> provider.update()
  end

  defp notify_amend_updated_order({:ok, {old, updated}}) do
    NotifyOrderUpdate.notify!(old, updated)
    updated
  end

  defp notify_amend_updated_order({:error, {:invalid_status, was, required, action}}) do
    warn_invalid_status(was, required, action)
  end
end
