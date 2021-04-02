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

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  @impl true
  def init(state), do: {:ok, state}

  @impl true
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
      received_at: received_at,
      meta: %{venue_symbols: venue_symbols}
    }
    |> TaiEvents.info()

    {:noreply, state}
  end

  @impl true
  def handle_cast({msg, received_at}, state) do
    TaiEvents.warn(%Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue,
      msg: msg,
      received_at: received_at |> Tai.Time.monotonic_to_date_time!()
    })

    {:noreply, state}
  end
end
