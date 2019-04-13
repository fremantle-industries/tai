defmodule Tai.VenueAdapters.OkEx.Stream.ProcessMessages do
  use GenServer
  alias Tai.{Events, VenueAdapters.OkEx.Stream}

  defmodule State do
    @type venue_id :: Tai.Venues.Adapter.venue_id()
    @type t :: %State{venue: venue_id}

    @enforce_keys ~w(venue)a
    defstruct ~w(venue)a
  end

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type state :: State.t()

  @spec start_link(venue: venue_id) :: GenServer.on_start()
  def start_link(venue: venue) do
    state = %State{venue: venue}
    name = venue |> to_name()
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec start_link(state) :: {:ok, state}
  def init(state), do: {:ok, state}

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  def handle_cast({%{"event" => "subscribe"}, _}, state), do: {:noreply, state}

  def handle_cast(
        {%{"table" => "futures/trade", "data" => data}, received_at},
        state
      ) do
    data |> Enum.each(&Stream.Trades.broadcast(&1, state.venue, received_at))
    {:noreply, state}
  end

  def handle_cast({msg, _received_at}, state) do
    Events.info(%Events.StreamMessageUnhandled{
      venue_id: state.venue,
      msg: msg
    })

    {:noreply, state}
  end
end
