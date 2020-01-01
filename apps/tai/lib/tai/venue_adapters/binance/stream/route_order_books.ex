defmodule Tai.VenueAdapters.Binance.Stream.RouteOrderBooks do
  use GenServer
  alias Tai.VenueAdapters.Binance.Stream.ProcessOrderBook

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

  @spec start_link(venue_id: venue_id, products: [product]) :: GenServer.on_start()
  def start_link(venue_id: venue_id, products: products) do
    stores = products |> build_stores()
    state = %State{venue: venue_id, stores: stores}
    name = venue_id |> to_name()

    GenServer.start_link(__MODULE__, state, name: name)
  end

  def init(state), do: {:ok, state}

  def handle_cast(
        {%{
           "data" => %{"e" => "depthUpdate", "s" => venue_symbol} = data,
           "stream" => _stream_name
         }, received_at},
        state
      ) do
    {state, venue_symbol}
    |> forward({:update, data, received_at})

    {:noreply, state}
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

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
