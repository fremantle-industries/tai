defmodule Tai.VenueAdapters.Ftx.Stream.RouteOrderBooks do
  use GenServer
  alias Tai.VenueAdapters.Ftx.Stream.ProcessOrderBook

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type venue_symbol :: Tai.Venues.Product.symbol()
    @type store_name :: atom
    @type stores :: %{optional(venue_symbol) => store_name}
    @type t :: %State{venue: venue_id, stores: stores}

    @enforce_keys ~w(venue stores)a
    defstruct ~w(venue stores)a
  end

  @type venue_id :: Tai.Venue.id()
  @type product :: Tai.Venues.Product.t()
  @type state :: State.t()

  @spec start_link(venue: venue_id, products: [product]) :: GenServer.on_start()
  def start_link(venue: venue, products: products) do
    stores = products |> build_stores()
    state = %State{venue: venue, stores: stores}
    name = venue |> to_name()

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_cast(
        {%{"type" => "partial", "market" => venue_symbol, "data" => data}, received_at},
        state
      ) do
    {state, venue_symbol}
    |> forward({:snapshot, data, received_at})

    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {%{"type" => "update", "market" => venue_symbol, "data" => data}, received_at},
        state
      ) do
    {state, venue_symbol}
    |> forward({:update, data, received_at})

    {:noreply, state}
  end

  @impl true
  def handle_cast({%{"type" => "subscribed"}, _}, state), do: {:noreply, state}

  defp build_stores(products) do
    products
    |> Enum.reduce(
      %{},
      &Map.put(&2, &1.venue_symbol, &1.venue_id |> ProcessOrderBook.to_name(&1.venue_symbol))
    )
  end

  defp forward({state, venue_symbol}, msg) do
    state.stores
    |> Map.fetch!(venue_symbol)
    |> GenServer.cast(msg)
  end
end
