defmodule Tai.VenueAdapters.Bitmex.Stream.RouteOrderBooks do
  use GenServer
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessOrderBook

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type venue_symbol :: Tai.Venues.Product.symbol()
    @type store_name :: atom
    @type stores :: %{optional(venue_symbol) => store_name}
    @type t :: %State{venue_id: venue_id, stores: stores}

    @enforce_keys ~w(venue_id stores)a
    defstruct ~w(venue_id stores)a
  end

  @type venue_id :: Tai.Venue.id()
  @type product :: Tai.Venues.Product.t()

  @spec start_link(venue_id: venue_id, order_books: [product]) :: GenServer.on_start()
  def start_link(venue_id: venue_id, order_books: order_books) do
    stores = order_books |> build_stores(venue_id)
    state = %State{venue_id: venue_id, stores: stores}
    name = venue_id |> to_name()

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue_id), do: :"#{__MODULE__}_#{venue_id}"

  def init(state), do: {:ok, state}

  def handle_cast({%{"request" => _}, _received_at}, state), do: {:noreply, state}

  def handle_cast(
        {
          %{"action" => "partial", "filter" => %{"symbol" => venue_symbol}, "data" => data},
          received_at
        },
        state
      ) do
    {state, venue_symbol}
    |> forward({:snapshot, data, received_at})

    {:noreply, state}
  end

  def handle_cast(
        {
          %{"action" => "insert", "data" => [%{"symbol" => venue_symbol} | _] = data},
          received_at
        },
        state
      ) do
    {state, venue_symbol}
    |> forward({:insert, data, received_at})

    {:noreply, state}
  end

  def handle_cast(
        {
          %{"action" => "update", "data" => [%{"symbol" => venue_symbol} | _] = data},
          received_at
        },
        state
      ) do
    {state, venue_symbol}
    |> forward({:update, data, received_at})

    {:noreply, state}
  end

  def handle_cast(
        {
          %{"action" => "delete", "data" => [%{"symbol" => venue_symbol} | _] = data},
          received_at
        },
        state
      ) do
    {state, venue_symbol}
    |> forward({:delete, data, received_at})

    {:noreply, state}
  end

  defp build_stores(order_books, venue_id) do
    order_books
    |> Enum.reduce(
      %{},
      &Map.put(&2, &1.venue_symbol, venue_id |> ProcessOrderBook.to_name(&1.venue_symbol))
    )
  end

  defp forward({state, venue_symbol}, msg) do
    state.stores
    |> Map.fetch!(venue_symbol)
    |> GenServer.cast(msg)
  end
end
