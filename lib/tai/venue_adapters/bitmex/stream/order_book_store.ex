defmodule Tai.VenueAdapters.Bitmex.Stream.OrderBookStore do
  use GenServer
  require Logger

  @type t :: %Tai.VenueAdapters.Bitmex.Stream.OrderBookStore{
          venue_id: atom,
          symbol: atom,
          table: map
        }

  @enforce_keys [:venue_id, :symbol, :table]
  defstruct [:venue_id, :symbol, :table]

  def start_link(venue_id: venue_id, symbol: symbol, exchange_symbol: exchange_symbol) do
    store = %Tai.VenueAdapters.Bitmex.Stream.OrderBookStore{
      venue_id: venue_id,
      symbol: symbol,
      table: %{}
    }

    GenServer.start_link(__MODULE__, store, name: to_name(venue_id, exchange_symbol))
  end

  @spec init(t) :: {:ok, t}
  def init(state) do
    {:ok, state}
  end

  @spec to_name(venue_id :: atom, exchange_symbol :: String.t()) :: atom
  def to_name(venue_id, exchange_symbol), do: :"#{__MODULE__}_#{venue_id}_#{exchange_symbol}"

  def handle_cast({:snapshot, data, received_at}, state) do
    normalized =
      data
      |> Enum.reduce(
        %{bids: %{}, asks: %{}, table: %{}},
        fn
          %{"id" => id, "price" => price, "side" => "Sell", "size" => size}, acc ->
            asks = acc.asks |> Map.put(price, {size, received_at, nil})
            table = acc.table |> Map.put(id, price)

            acc
            |> Map.put(:asks, asks)
            |> Map.put(:table, table)

          %{"id" => id, "price" => price, "side" => "Buy", "size" => size}, acc ->
            bids = acc.bids |> Map.put(price, {size, received_at, nil})
            table = acc.table |> Map.put(id, price)

            acc
            |> Map.put(:bids, bids)
            |> Map.put(:table, table)
        end
      )

    snapshot = %Tai.Markets.OrderBook{
      venue_id: state.venue_id,
      product_symbol: state.symbol,
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
            asks = acc.asks |> Map.put(price, {size, received_at, nil})
            table = acc.table |> Map.put(id, price)

            acc
            |> Map.put(:asks, asks)
            |> Map.put(:table, table)

          %{"id" => id, "price" => price, "side" => "Buy", "size" => size}, acc ->
            bids = acc.bids |> Map.put(price, {size, received_at, nil})
            table = acc.table |> Map.put(id, price)

            acc
            |> Map.put(:bids, bids)
            |> Map.put(:table, table)
        end
      )

    update = %Tai.Markets.OrderBook{
      venue_id: state.venue_id,
      product_symbol: state.symbol,
      bids: normalized.bids,
      asks: normalized.asks
    }

    state.venue_id
    |> Tai.Markets.OrderBook.to_name(state.symbol)
    |> Tai.Markets.OrderBook.update(update)

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
            asks = acc.asks |> Map.put(price, {size, received_at, nil})
            Map.put(acc, :asks, asks)

          %{"id" => id, "side" => "Buy", "size" => size}, acc ->
            price = Map.fetch!(state.table, id)
            bids = acc.bids |> Map.put(price, {size, received_at, nil})
            Map.put(acc, :bids, bids)
        end
      )

    update = %Tai.Markets.OrderBook{
      venue_id: state.venue_id,
      product_symbol: state.symbol,
      bids: normalized.bids,
      asks: normalized.asks
    }

    state.venue_id
    |> Tai.Markets.OrderBook.to_name(state.symbol)
    |> Tai.Markets.OrderBook.update(update)

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
            asks = acc.asks |> Map.put(price, {0, received_at, nil})
            Map.put(acc, :asks, asks)

          %{"id" => id, "side" => "Buy"}, acc ->
            price = Map.fetch!(state.table, id)
            bids = acc.bids |> Map.put(price, {0, received_at, nil})
            Map.put(acc, :bids, bids)
        end
      )

    update = %Tai.Markets.OrderBook{
      venue_id: state.venue_id,
      product_symbol: state.symbol,
      bids: normalized.bids,
      asks: normalized.asks
    }

    state.venue_id
    |> Tai.Markets.OrderBook.to_name(state.symbol)
    |> Tai.Markets.OrderBook.update(update)

    {:noreply, state}
  end
end
