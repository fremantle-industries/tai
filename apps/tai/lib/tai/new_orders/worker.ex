defmodule Tai.NewOrders.Worker do
  use GenServer

  alias Tai.Venues.Adapter

  alias Tai.NewOrders.{
    Order,
    OrderTransitionWorker,
    Services,
    SubmissionFactory,
    Responses,
    Transition
  }

  defmodule State do
    defstruct ~w[tasks]a
  end

  @type submission :: SubmissionFactory.submission()
  @type order :: Order.t()
  @type status :: atom
  @type transition :: Transition.t()
  @type invalid_status_error_reason :: {:invalid_status, was :: status, transition}
  @type create_result :: {:ok, order} | {:error, Adapter.create_order_error_reason()}
  @type cancel_result :: {:ok, order} | {:error, invalid_status_error_reason | Adapter.cancel_order_error_reason()}
  @type amend_attrs :: %{
          optional(:price) => Decimal.t(),
          optional(:qty) => Decimal.t()
        }
  @type amend_result ::
          {:ok, updated :: order}
          | {:error, invalid_status_error_reason | Adapter.amend_order_error_reason()}
  @type amend_bulk_reject_reason :: invalid_status_error_reason
  @type amend_bulk_result :: [{:ok, updated :: order} | {:error, amend_bulk_reject_reason}]

  def start_link(_) do
    state = %State{tasks: %{}}
    GenServer.start_link(__MODULE__, state)
  end

  @spec create(pid, submission) :: create_result
  def create(pid, submission) do
    GenServer.call(pid, {:create, submission})
  end

  @spec cancel(pid, order) :: cancel_result
  def cancel(pid, order) do
    GenServer.call(pid, {:cancel, order})
  end

  @spec amend(pid, order, amend_attrs) :: amend_result
  def amend(pid, order, attrs) do
    GenServer.call(pid, {:amend, order, attrs})
  end

  @spec amend_bulk(pid, [{order, amend_attrs}]) :: amend_bulk_result()
  def amend_bulk(pid, amend_set) do
    GenServer.call(pid, {:amend_bulk, amend_set})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:create, submission}, _from, state) do
    submission
    |> enqueue()
    |> case do
      {:ok, order} ->
        state =
          with_task(
            fn ->
              if Tai.Settings.send_orders?() do
                try do
                  order
                  |> send_create_to_venue()
                  |> parse_create_response()
                rescue
                  e ->
                    {e, __STACKTRACE__}
                    |> rescue_create_venue_adapter_error(order)
                end
              else
                order.client_id
                |> skip()
              end
            end,
            state
          )

        {:reply, {:ok, order}, state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:cancel, order}, _from, state) do
    order
    |> pend_cancel()
    |> case do
      {:ok, order_pending_cancel} ->
        state =
          with_task(
            fn ->
              try do
                order_pending_cancel
                |> send_cancel_to_venue()
                |> parse_cancel_response()
              rescue
                e ->
                  {e, __STACKTRACE__}
                  |> rescue_cancel_venue_adapter_error(order_pending_cancel)
              end
            end,
            state
          )

        {:reply, {:ok, order_pending_cancel}, state}

      {:error, {:invalid_status, _, _}} = error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:amend, order, attrs}, _from, state) do
    order
    |> pend_amend()
    |> case do
      {:ok, order_pending_amend} ->
        state =
          with_task(
            fn ->
              try do
                order_pending_amend
                |> send_amend_to_venue(attrs)
                |> parse_amend_response()
              rescue
                e ->
                  {e, __STACKTRACE__}
                  |> rescue_amend_venue_adapter_error(order_pending_amend)
              end
            end,
            state
          )

        {:reply, {:ok, order_pending_amend}, state}

      {:error, {:invalid_status, _, _}} = error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:amend_bulk, amend_set}, _from, state) do
    pending_orders = pend_amend_bulk(amend_set)

    state =
      with_task(
        fn ->
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
            |> send_amend_bulk_to_venue()
            |> parse_amend_bulk_response(amend_set)
          rescue
            e ->
              {e, __STACKTRACE__}
              |> rescue_amend_bulk_venue_adapter_error(amend_set)
          end
        end,
        state
      )

    {:reply, pending_orders, state}
  end

  defp with_task(callback, state) do
    task = Task.async(callback)
    tasks = Map.put(state.tasks, task.ref, task)
    %{state | tasks: tasks}
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

  ###################
  # create order
  ###################
  defp enqueue(submission) do
    Services.EnqueueOrder.call(submission)
  end

  defp send_create_to_venue(order) do
    result = Tai.Venues.Client.create_order(order)
    {result, order}
  end

  defp parse_create_response({{:ok, %Responses.CreateAccepted{} = response}, order}) do
    OrderTransitionWorker.apply(order.client_id, %{
      venue_order_id: response.id,
      last_received_at: Tai.Time.monotonic_to_date_time!(response.received_at),
      last_venue_timestamp: response.venue_timestamp,
      __type__: :accept_create
    })
  end

  defp parse_create_response({{:error, reason}, order}) do
    OrderTransitionWorker.apply(order.client_id, %{
      reason: reason,
      __type__: :venue_create_error
    })
  end

  defp rescue_create_venue_adapter_error({error, stacktrace}, order) do
    OrderTransitionWorker.apply(order.client_id, %{
      error: error,
      stacktrace: stacktrace,
      __type__: :rescue_create_error
    })
  end

  defp skip(client_id) do
    OrderTransitionWorker.apply(client_id, %{
      __type__: :skip
    })
  end

  ###################
  # cancel order
  ###################
  defp pend_cancel(order) do
    OrderTransitionWorker.apply(order.client_id, %{
      __type__: :pend_cancel
    })
  end

  defp send_cancel_to_venue(order) do
    {order, Tai.Venues.Client.cancel_order(order)}
  end

  defp parse_cancel_response({order, {:ok, %Responses.CancelAccepted{} = response}}) do
    OrderTransitionWorker.apply(order.client_id, %{
      last_received_at: Tai.Time.monotonic_to_date_time!(response.received_at),
      last_venue_timestamp: response.venue_timestamp,
      __type__: :accept_cancel
    })
  end

  defp parse_cancel_response({order, {:error, reason}}) do
    OrderTransitionWorker.apply(order.client_id, %{
      reason: reason,
      __type__: :venue_cancel_error
    })
  end

  defp rescue_cancel_venue_adapter_error({error, stacktrace}, order) do
    OrderTransitionWorker.apply(order.client_id, %{
      error: error,
      stacktrace: stacktrace,
      __type__: :rescue_cancel_error
    })
  end

  ###################
  # amend order
  ###################
  defp pend_amend(order) do
    OrderTransitionWorker.apply(order.client_id, %{
      __type__: :pend_amend
    })
  end

  def send_amend_to_venue(order, attrs) do
    {order, Tai.Venues.Client.amend_order(order, attrs)}
  end

  defp parse_amend_response({order, {:ok, %Responses.AmendAccepted{} = response}}) do
    OrderTransitionWorker.apply(order.client_id, %{
      last_received_at: response.received_at,
      last_venue_timestamp: response.venue_timestamp,
      __type__: :accept_amend
    })
  end

  defp parse_amend_response({order, {:error, reason}}) do
    OrderTransitionWorker.apply(order.client_id, %{
      reason: reason,
      __type__: :venue_amend_error
    })
  end

  defp rescue_amend_venue_adapter_error({error, stacktrace}, order) do
    OrderTransitionWorker.apply(order.client_id, %{
      error: error,
      stacktrace: stacktrace,
      __type__: :rescue_amend_error
    })
  end

  ###################
  # amend bulk order
  ###################
  defp pend_amend_bulk(amend_set) do
    amend_set
    |> Enum.map(fn {order, _} ->
      pend_amend(order)
    end)
  end

  defp send_amend_bulk_to_venue(orders) do
    Tai.Venues.Client.amend_bulk_orders(orders)
  end

  defp parse_amend_bulk_response(
         {:ok, %Responses.AmendBulk{orders: amend_responses}},
         amend_set
       ) do
    amend_responses
    |> Enum.map(fn amend_response ->
      order =
        amend_set
        |> Enum.find(fn {o, _} -> o.venue_order_id == amend_response.id end)
        |> elem(0)

      OrderTransitionWorker.apply(order.client_id, %{
        last_received_at: amend_response.received_at,
        last_venue_timestamp: amend_response.venue_timestamp,
        __type__: :accept_amend
      })
    end)
  end

  defp parse_amend_bulk_response({:error, reason}, amend_set) do
    amend_set
    |> Enum.map(fn {order, _} ->
      OrderTransitionWorker.apply(order.client_id, %{
        reason: reason,
        __type__: :venue_amend_error
      })
    end)
  end

  defp rescue_amend_bulk_venue_adapter_error({error, stacktrace}, amend_set) do
    amend_set
    |> Enum.map(fn {order, _} ->
      OrderTransitionWorker.apply(order.client_id, %{
        error: error,
        stacktrace: stacktrace,
        __type__: :rescue_amend_error
      })
    end)
  end
end
