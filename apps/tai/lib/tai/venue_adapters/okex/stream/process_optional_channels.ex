defmodule Tai.VenueAdapters.OkEx.Stream.ProcessOptionalChannels do
  use GenServer
  alias Tai.VenueAdapters.OkEx.Stream

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type t :: %State{venue: venue_id}

    @enforce_keys ~w(venue)a
    defstruct ~w(venue)a
  end

  @type venue_id :: Tai.Venue.id()
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

  @accepted_trade_types ~w(futures spot swap) |> Enum.map(&"#{&1}/trade")
  def handle_cast({%{"table" => table, "data" => data}, received_at}, state)
      when table in @accepted_trade_types do
    data |> Enum.each(&Stream.Trades.broadcast(&1, state.venue, received_at))
    {:noreply, state}
  end

  def handle_cast({"pong", _received_at}, state) do
    {:noreply, state}
  end

  def handle_cast({msg, received_at}, state) do
    %Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue,
      msg: msg,
      received_at: received_at
    }
    |> TaiEvents.warn()

    {:noreply, state}
  end
end
