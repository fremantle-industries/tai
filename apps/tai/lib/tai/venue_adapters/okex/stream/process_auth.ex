defmodule Tai.VenueAdapters.OkEx.Stream.ProcessAuth do
  use GenServer
  alias Tai.VenueAdapters.OkEx.{ClientId, Stream}

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type t :: %State{venue: atom}

    @enforce_keys ~w[venue]a
    defstruct ~w[venue]a
  end

  @type venue_id :: Tai.Venue.id()
  @type state :: State.t()

  @spec start_link(list) :: GenServer.on_start()
  def start_link(venue: venue) do
    state = %State{venue: venue}
    name = process_name(venue)
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec process_name(venue_id) :: atom
  def process_name(venue), do: :"#{__MODULE__}_#{venue}"

  @impl true
  def init(state) do
    {:ok, state}
  end

  @product_types ["swap/order", "futures/order", "spot/order"]

  @impl true
  def handle_cast(
        {%{"table" => table, "data" => orders}, received_at},
        state
      )
      when table in @product_types do
    orders
    |> Enum.each(fn %{"client_oid" => venue_client_id} = order_msg ->
      venue_client_id
      |> ClientId.from_base32()
      |> Stream.UpdateOrder.apply(order_msg, received_at, state)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_cast({msg, received_at}, state) do
    {:ok, last_received_at} = received_at |> Tai.Time.monotonic_to_date_time()

    TaiEvents.warn(%Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue,
      msg: msg,
      received_at: last_received_at
    })

    {:noreply, state}
  end
end
