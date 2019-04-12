defmodule Tai.VenueAdapters.OkEx.Stream.ProcessOrderBooks do
  use GenServer
  alias Tai.{Venues, VenueAdapters.OkEx.Stream}

  defmodule State do
    @type venue_id :: Venues.Adapter.venue_id()
    @type t :: %State{venue: venue_id}

    @enforce_keys ~w(venue)a
    defstruct ~w(venue)a
  end

  @type venue_id :: Venues.Adapter.venue_id()
  @type product :: Venues.Product.t()
  @type state :: State.t()

  @spec start_link(venue: venue_id, products: [product]) :: GenServer.on_start()
  def start_link(venue: venue, products: _products) do
    state = %State{venue: venue}
    name = venue |> to_name()
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec init(state) :: {:ok, state}
  def init(state), do: {:ok, state}

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  def handle_cast(
        {%{"action" => "partial", "data" => data}, received_at},
        state
      ) do
    data
    |> Enum.each(fn %{"instrument_id" => venue_symbol} = msg ->
      state.venue
      |> Stream.OrderBookStore.to_name(venue_symbol)
      |> GenServer.cast({:snapshot, msg, received_at})
    end)

    {:noreply, state}
  end

  def handle_cast(
        {%{"action" => "update", "data" => data}, received_at},
        state
      ) do
    data
    |> Enum.each(fn %{"instrument_id" => venue_symbol} = msg ->
      state.venue
      |> Stream.OrderBookStore.to_name(venue_symbol)
      |> GenServer.cast({:update, msg, received_at})
    end)

    {:noreply, state}
  end
end
