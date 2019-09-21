defmodule Tai.VenueAdapters.OkEx.Stream.ProcessOrderBooks do
  use GenServer
  alias Tai.VenueAdapters.OkEx.Stream.OrderBookStore

  defmodule State do
    @type venue_id :: Tai.Venues.Adapter.venue_id()
    @type venue_symbol :: Tai.Venues.Product.symbol()
    @type store_name :: atom
    @type stores :: %{optional(venue_symbol) => store_name}
    @type t :: %State{venue: venue_id, stores: stores}

    @enforce_keys ~w(venue stores)a
    defstruct ~w(venue stores)a
  end

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type product :: Tai.Venues.Product.t()
  @type state :: State.t()

  @spec start_link(venue: venue_id, products: [product]) :: GenServer.on_start()
  def start_link(venue: venue, products: products) do
    stores = products |> build_stores(venue)
    state = %State{venue: venue, stores: stores}
    name = venue |> to_name()

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec init(state) :: {:ok, state}
  def init(state), do: {:ok, state}

  def handle_cast(
        {%{"action" => "partial", "data" => data}, received_at},
        state
      ) do
    data
    |> Enum.each(fn %{"instrument_id" => venue_symbol} = msg ->
      {state, venue_symbol}
      |> forward({:snapshot, msg, received_at})
    end)

    {:noreply, state}
  end

  def handle_cast(
        {%{"action" => "update", "data" => data}, received_at},
        state
      ) do
    data
    |> Enum.each(fn %{"instrument_id" => venue_symbol} = msg ->
      {state, venue_symbol}
      |> forward({:update, msg, received_at})
    end)

    {:noreply, state}
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  defp build_stores(products, venue_id) do
    products
    |> Enum.reduce(
      %{},
      &Map.put(&2, &1.venue_symbol, venue_id |> OrderBookStore.to_name(&1.venue_symbol))
    )
  end

  defp forward({state, venue_symbol}, msg) do
    state.stores
    |> Map.fetch!(venue_symbol)
    |> GenServer.cast(msg)
  end
end
