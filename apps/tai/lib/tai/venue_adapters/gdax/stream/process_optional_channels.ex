defmodule Tai.VenueAdapters.Gdax.Stream.ProcessOptionalChannels do
  use GenServer

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type t :: %State{venue: venue_id}

    @enforce_keys ~w(venue)a
    defstruct ~w(venue)a
  end

  @type venue_id :: Tai.Venue.id()

  @spec start_link(venue_id: venue_id) :: GenServer.on_start()
  def start_link(venue_id: venue_id) do
    state = %State{venue: venue_id}
    name = venue_id |> to_name()

    GenServer.start_link(__MODULE__, state, name: name)
  end

  def init(state), do: {:ok, state}

  def handle_cast(
        {
          %{
            "channels" => [%{"name" => channel_name, "product_ids" => venue_symbols}],
            "type" => "subscriptions"
          },
          received_at
        },
        state
      ) do
    %Tai.Events.StreamSubscribeOk{
      venue: state.venue,
      channel_name: channel_name,
      venue_symbols: venue_symbols,
      received_at: received_at
    }
    |> TaiEvents.info()

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

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"
end
