defmodule Tai.VenueAdapters.OkEx.Stream.ProcessAuth do
  use GenServer
  alias Tai.VenueAdapters.OkEx.{ClientId, Stream}

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type t :: %State{venue: atom}

    @enforce_keys ~w(venue)a
    defstruct ~w(venue)a
  end

  @type venue_id :: Tai.Venue.id()
  @type state :: State.t()

  def start_link(venue: venue) do
    state = %State{venue: venue}
    name = venue |> to_name()
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec init(state) :: {:ok, state}
  def init(state) do
    Process.flag(:trap_exit, true)
    {:ok, state}
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  @product_types ["swap/order", "futures/order"]
  def handle_cast(
        {%{"table" => table, "data" => orders}, received_at},
        state
      )
      when table in @product_types do
    orders
    |> Enum.each(fn %{"client_oid" => venue_client_id} = venue_order ->
      venue_client_id
      |> ClientId.from_base32()
      |> Stream.UpdateOrder.update(venue_order, received_at)
    end)

    {:noreply, state}
  end

  def handle_cast({msg, received_at}, state) do
    TaiEvents.warn(%Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue,
      msg: msg,
      received_at: received_at
    })

    {:noreply, state}
  end

  def handle_info({_reference, response}, state) do
    response |> notify
    {:noreply, state}
  end

  defp notify(:ok), do: nil

  defp notify({:ok, {old, updated}}) do
    Tai.Trading.NotifyOrderUpdate.notify!(old, updated)
  end

  defp notify({:error, {:invalid_status, was, required, %action_name{} = action}}) do
    TaiEvents.warn(%Tai.Events.OrderUpdateInvalidStatus{
      was: was,
      required: required,
      client_id: action.client_id,
      action: action_name
    })
  end

  defp notify({:error, {:not_found, %action_name{} = action}}) do
    TaiEvents.warn(%Tai.Events.OrderUpdateNotFound{
      client_id: action.client_id,
      action: action_name
    })
  end
end
