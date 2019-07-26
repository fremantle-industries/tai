defmodule Tai.VenueAdapters.OkEx.Stream.ProcessAuth do
  use GenServer
  alias Tai.Events
  alias Tai.VenueAdapters.OkEx.{ClientId, Stream}

  defmodule State do
    @type venue_id :: Tai.Venues.Adapter.venue_id()
    @type t :: %State{venue: atom, tasks: map}

    @enforce_keys ~w(venue tasks)a
    defstruct ~w(venue tasks)a
  end

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type state :: State.t()

  def start_link(venue: venue) do
    state = %State{venue: venue, tasks: %{}}
    name = venue |> to_name()
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec init(state) :: {:ok, state}
  def init(state), do: {:ok, state}

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  @futures_order "futures/order"
  @swap_order "swap/order"
  def handle_cast(
        {%{"table" => table, "data" => orders}, received_at},
        state
      )
      when table == @futures_order or table == @swap_order do
    new_tasks =
      orders
      |> Enum.map(fn %{"client_oid" => venue_client_id} = venue_order ->
        Task.async(fn ->
          venue_client_id
          |> ClientId.from_base32()
          |> Stream.UpdateOrder.update(venue_order, received_at)
        end)
      end)
      |> Enum.reduce(%{}, fn t, acc -> Map.put(acc, t.ref, true) end)
      |> Map.merge(state.tasks)

    new_state = state |> Map.put(:tasks, new_tasks)

    {:noreply, new_state}
  end

  def handle_cast({msg, _received_at}, state) do
    Events.info(%Events.StreamMessageUnhandled{venue_id: state.venue, msg: msg})
    {:noreply, state}
  end

  def handle_info({_reference, response}, state) do
    response |> notify
    {:noreply, state}
  end

  def handle_info({:DOWN, reference, :process, _pid, :normal}, state) do
    new_tasks = state.tasks |> Map.delete(reference)
    new_state = state |> Map.put(:tasks, new_tasks)
    {:noreply, new_state}
  end

  defp notify(:ok), do: nil

  defp notify({_, _, {:ok, {old, updated}}}) do
    Tai.Trading.Orders.updated!(old, updated)
  end

  defp notify({client_id, action, {:error, {:invalid_status, was, required}}}) do
    Tai.Events.info(%Tai.Events.OrderUpdateInvalidStatus{
      client_id: client_id,
      action: action,
      was: was,
      required: required
    })
  end

  defp notify({client_id, action, {:error, :not_found}}) do
    Tai.Events.info(%Tai.Events.OrderUpdateNotFound{
      client_id: client_id,
      action: action
    })
  end
end
