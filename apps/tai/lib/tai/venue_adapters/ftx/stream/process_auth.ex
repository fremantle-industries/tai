defmodule Tai.VenueAdapters.Ftx.Stream.ProcessAuth do
  use GenServer
  alias Tai.VenueAdapters.Ftx.Stream

  defmodule State do
    @type venue :: Tai.Venue.id()
    @type t :: %State{venue: venue}

    @enforce_keys ~w[venue]a
    defstruct ~w[venue]a
  end

  @type venue :: Tai.Venue.id()
  @type state :: State.t()

  def start_link(venue: venue) do
    state = %State{venue: venue}
    name = venue |> process_name()
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec process_name(venue) :: atom
  def process_name(venue), do: :"#{__MODULE__}_#{venue}"

  @impl true
  def init(state) do
    Process.flag(:trap_exit, true)
    {:ok, state}
  end

  @impl true
  def handle_cast({%{"channel" => "orders", "type" => "update", "data" => venue_order}, received_at}, state) do
    Stream.UpdateOrder.apply(venue_order, received_at, state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({%{"channel" => "orders", "type" => "subscribed"}, received_at}, state) do
    TaiEvents.info(%Tai.Events.StreamSubscribeOk{
      venue: state.venue,
      channel_name: "orders",
      received_at: received_at,
      meta: %{},
    })

    {:noreply, state}
  end

  @impl true
  def handle_cast({msg, received_at}, state) do
    {:ok, last_received_at} = received_at |> Tai.Time.monotonic_to_date_time()

    TaiEvents.warning(%Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue,
      msg: msg,
      received_at: last_received_at
    })

    {:noreply, state}
  end
end
