defmodule Tai.VenueAdapters.Binance.Stream.ProcessOptionalChannels do
  use GenServer
  alias Tai.VenueAdapters.Binance.Stream

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type t :: %State{venue_id: venue_id}

    @enforce_keys ~w(venue_id)a
    defstruct ~w(venue_id)a
  end

  @type venue_id :: Tai.Venue.id()

  def start_link(venue_id: venue_id) do
    state = %State{venue_id: venue_id}
    name = venue_id |> to_name()

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue_id), do: :"#{__MODULE__}_#{venue_id}"

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_cast(
        {%{"e" => "trade"} = trade, received_at},
        state
      ) do
    Stream.Trades.broadcast(trade, state.venue_id, received_at)
    {:noreply, state}
  end

  @impl true
  def handle_cast({msg, received_at}, state) do
    TaiEvents.warn(%Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue_id,
      msg: msg,
      received_at: received_at |> Tai.Time.monotonic_to_date_time!()
    })

    {:noreply, state}
  end
end
