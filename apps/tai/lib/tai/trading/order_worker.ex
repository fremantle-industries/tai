defmodule Tai.Trading.OrderWorker do
  use GenServer

  alias Tai.Trading.OrderStore.Actions

  alias Tai.Trading.{
    NotifyOrderUpdate,
    OrderResponses,
    OrderStore,
    OrderSubmissions,
    Orders,
    Order
  }

  defmodule State do
    defstruct ~w[tasks]a
  end

  @type submission :: OrderSubmissions.Factory.submission()
  @type order :: Order.t()
  @type create_response :: {:ok, order}

  def start_link(_) do
    state = %State{tasks: %{}}
    GenServer.start_link(__MODULE__, state)
  end

  @spec create(pid, submission) :: create_response
  def create(pid, submission) do
    GenServer.call(pid, {:create, submission})
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
            |> send_to_venue()
            |> parse_response()
            |> notify_updated_order()
          rescue
            e ->
              {e, __STACKTRACE__}
              |> rescue_venue_adapter_error(order)
              |> notify_updated_order()
          end
        else
          order.client_id
          |> skip!
          |> notify_updated_order()
        end
      end)

    tasks = Map.put(state.tasks, task.ref, task)
    state = %{state | tasks: tasks}
    {:reply, {:ok, order}, state}
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

  defp notify_initial_updated_order(order) do
    NotifyOrderUpdate.notify!(nil, order)
  end

  defp send_to_venue(order) do
    result = Tai.Venues.Client.create_order(order)
    {result, order}
  end

  defp parse_response({
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

  defp parse_response({
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

  defp parse_response({
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

  defp parse_response({
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

  defp parse_response({
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

  defp parse_response({{:error, reason}, order}) do
    %Actions.CreateError{
      client_id: order.client_id,
      reason: reason,
      last_received_at: Tai.Time.monotonic_time()
    }
    |> OrderStore.update()
  end

  defp rescue_venue_adapter_error(reason, order) do
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

  defp notify_updated_order({:ok, {prev, current}}),
    do: NotifyOrderUpdate.notify!(prev, current)

  defp notify_updated_order({:error, {:invalid_status, _, _, %action_name{}}})
       when action_name == Actions.AcceptCreate do
    :ok
  end
end
