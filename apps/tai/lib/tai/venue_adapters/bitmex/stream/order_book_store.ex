defmodule Tai.VenueAdapters.Bitmex.Stream.OrderBookStore do
  use GenServer

  defmodule State do
    @type venue_id :: Tai.Venues.Adapter.venue_id()
    @type product_symbol :: Tai.Venues.Product.symbol()
    @type t :: %State{
            venue_id: venue_id,
            symbol: product_symbol,
            table: %{optional(String.t()) => number}
          }

    @enforce_keys ~w(venue_id symbol table)a
    defstruct ~w(venue_id symbol table)a
  end

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type product_symbol :: Tai.Venues.Product.symbol()
  @type venue_symbol :: Tai.Venues.Product.venue_symbol()
  @type state :: State.t()

  @spec start_link(venue_id: venue_id, symbol: product_symbol, venue_symbol: venue_symbol) ::
          GenServer.on_start()
  def start_link(venue_id: venue_id, symbol: symbol, venue_symbol: venue_symbol) do
    name = to_name(venue_id, venue_symbol)

    state = %State{
      venue_id: venue_id,
      symbol: symbol,
      table: %{}
    }

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec init(state) :: {:ok, state}
  def init(state), do: {:ok, state}

  def handle_cast({:snapshot, data, received_at}, state) do
    normalized =
      data
      |> Enum.reduce(
        %{bids: %{}, asks: %{}, table: %{}},
        fn
          %{"id" => id, "price" => price, "side" => "Sell", "size" => size}, acc ->
            asks = acc.asks |> Map.put(price, size)
            table = acc.table |> Map.put(id, price)

            acc
            |> Map.put(:asks, asks)
            |> Map.put(:table, table)

          %{"id" => id, "price" => price, "side" => "Buy", "size" => size}, acc ->
            bids = acc.bids |> Map.put(price, size)
            table = acc.table |> Map.put(id, price)

            acc
            |> Map.put(:bids, bids)
            |> Map.put(:table, table)
        end
      )

    snapshot = %Tai.Markets.OrderBook{
      venue_id: state.venue_id,
      product_symbol: state.symbol,
      last_received_at: received_at,
      bids: normalized.bids,
      asks: normalized.asks
    }

    :ok = Tai.Markets.OrderBook.replace(snapshot)
    new_table = Map.merge(state.table, normalized.table)
    new_state = Map.put(state, :table, new_table)

    {:noreply, new_state}
  end

  def handle_cast({:insert, data, received_at}, state) do
    normalized =
      data
      |> Enum.reduce(
        %{bids: %{}, asks: %{}, table: %{}},
        fn
          %{"id" => id, "price" => price, "side" => "Sell", "size" => size}, acc ->
            asks = acc.asks |> Map.put(price, size)
            table = acc.table |> Map.put(id, price)

            acc
            |> Map.put(:asks, asks)
            |> Map.put(:table, table)

          %{"id" => id, "price" => price, "side" => "Buy", "size" => size}, acc ->
            bids = acc.bids |> Map.put(price, size)
            table = acc.table |> Map.put(id, price)

            acc
            |> Map.put(:bids, bids)
            |> Map.put(:table, table)
        end
      )

    %Tai.Markets.OrderBook{
      venue_id: state.venue_id,
      product_symbol: state.symbol,
      last_received_at: received_at,
      bids: normalized.bids,
      asks: normalized.asks
    }
    |> Tai.Markets.OrderBook.update()

    new_table = Map.merge(state.table, normalized.table)
    new_state = Map.put(state, :table, new_table)

    {:noreply, new_state}
  end

  def handle_cast({:update, data, received_at}, state) do
    normalized =
      data
      |> Enum.reduce(
        %{bids: %{}, asks: %{}},
        fn
          %{"id" => id, "side" => "Sell", "size" => size}, acc ->
            price = Map.fetch!(state.table, id)
            asks = acc.asks |> Map.put(price, size)
            Map.put(acc, :asks, asks)

          %{"id" => id, "side" => "Buy", "size" => size}, acc ->
            price = Map.fetch!(state.table, id)
            bids = acc.bids |> Map.put(price, size)
            Map.put(acc, :bids, bids)
        end
      )

    %Tai.Markets.OrderBook{
      venue_id: state.venue_id,
      product_symbol: state.symbol,
      last_received_at: received_at,
      bids: normalized.bids,
      asks: normalized.asks
    }
    |> Tai.Markets.OrderBook.update()

    {:noreply, state}
  end

  def handle_cast({:delete, data, received_at}, state) do
    normalized =
      data
      |> Enum.reduce(
        %{bids: %{}, asks: %{}},
        fn
          %{"id" => id, "side" => "Sell"}, acc ->
            price = Map.fetch!(state.table, id)
            asks = acc.asks |> Map.put(price, 0)
            Map.put(acc, :asks, asks)

          %{"id" => id, "side" => "Buy"}, acc ->
            price = Map.fetch!(state.table, id)
            bids = acc.bids |> Map.put(price, 0)
            Map.put(acc, :bids, bids)
        end
      )

    %Tai.Markets.OrderBook{
      venue_id: state.venue_id,
      product_symbol: state.symbol,
      last_received_at: received_at,
      bids: normalized.bids,
      asks: normalized.asks
    }
    |> Tai.Markets.OrderBook.update()

    {:noreply, state}
  end

  @spec to_name(venue_id, venue_symbol :: String.t()) :: atom
  def to_name(venue_id, venue_symbol), do: :"#{__MODULE__}_#{venue_id}_#{venue_symbol}"
end
