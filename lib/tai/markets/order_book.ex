defmodule Tai.Markets.OrderBook do
  @moduledoc """
  Manage and query the state for an order book for a symbol on a feed
  """

  use GenServer

  alias Tai.PubSub
  alias Tai.Markets.{OrderBook, PriceLevel, Quote}

  defstruct bids: %{}, asks: %{}

  def start_link(feed_id: feed_id, symbol: symbol) do
    GenServer.start_link(
      __MODULE__,
      %{
        feed_id: feed_id,
        symbol: symbol,
        order_book: %OrderBook{}
      },
      name: to_name(feed_id: feed_id, symbol: symbol)
    )
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:quotes, depth: depth}, _from, state) do
    order_book = %OrderBook{
      bids: state |> Map.get(:order_book) |> ordered_bids |> take(depth),
      asks: state |> Map.get(:order_book) |> ordered_asks |> take(depth)
    }

    {:reply, {:ok, order_book}, state}
  end

  def handle_call(:bid, _from, state) do
    bid =
      state.order_book
      |> ordered_bids
      |> List.first()

    {:reply, {:ok, bid}, state}
  end

  def handle_call({:bids, depth}, _from, state) do
    bids =
      state.order_book
      |> ordered_bids
      |> take(depth)

    {:reply, {:ok, bids}, state}
  end

  def handle_call(:ask, _from, state) do
    ask =
      state.order_book
      |> ordered_asks
      |> List.first()

    {:reply, {:ok, ask}, state}
  end

  def handle_call({:asks, depth}, _from, state) do
    asks =
      state.order_book
      |> ordered_asks
      |> take(depth)

    {:reply, {:ok, asks}, state}
  end

  def handle_call({:replace, snapshot}, _from, state) do
    PubSub.broadcast(
      {:order_book_snapshot, state.feed_id, state.symbol},
      {:order_book_snapshot, state.feed_id, state.symbol, snapshot}
    )

    new_state = state |> Map.put(:order_book, snapshot)

    {:reply, :ok, new_state}
  end

  def handle_call({:update, %OrderBook{bids: bids, asks: asks} = changes}, _from, state) do
    PubSub.broadcast(
      {:order_book_changes, state.feed_id, state.symbol},
      {:order_book_changes, state.feed_id, state.symbol, changes}
    )

    new_order_book =
      state.order_book
      |> update_side(:bids, bids)
      |> update_side(:asks, asks)

    new_state =
      state
      |> Map.put(:order_book, new_order_book)

    {:reply, :ok, new_state}
  end

  @doc """
  Return bid/asks up to the given depth. If depth is not provided it returns
  the full order book.
  """
  def quotes(name, depth \\ :all) do
    GenServer.call(name, {:quotes, depth: depth})
  end

  @doc """
  Return the bid/ask at the top of the book
  """
  def inside_quote(feed_id, symbol) do
    [feed_id: feed_id, symbol: symbol]
    |> to_name()
    |> quotes(1)
    |> case do
      {:ok, %{bids: bids, asks: asks}} ->
        with top_bid <- List.first(bids),
             top_ask <- List.first(asks) do
          {:ok, %Quote{bid: top_bid, ask: top_ask}}
        end
    end
  end

  def bid(name) do
    GenServer.call(name, :bid)
  end

  def bids(name, depth \\ :all) do
    GenServer.call(name, {:bids, depth})
  end

  def ask(name) do
    GenServer.call(name, :ask)
  end

  def asks(name, depth \\ :all) do
    GenServer.call(name, {:asks, depth})
  end

  def replace(name, %OrderBook{} = replacement) do
    GenServer.call(name, {:replace, replacement})
  end

  def update(name, %OrderBook{} = changes) do
    GenServer.call(name, {:update, changes})
  end

  @doc """
  Returns an atom that will identify the process

  ## Examples

    iex> Tai.Markets.OrderBook.to_name(feed_id: :my_test_feed, symbol: :btc_usd)
    Tai.Markets.OrderBook_my_test_feed_btc_usd
  """
  def to_name(feed_id: feed_id, symbol: symbol) do
    :"#{__MODULE__}_#{feed_id}_#{symbol}"
  end

  defp ordered_bids(state) do
    state.bids
    |> Map.keys()
    |> Enum.sort()
    |> Enum.reverse()
    |> with_price_levels(state.bids)
  end

  defp ordered_asks(state) do
    state.asks
    |> Map.keys()
    |> Enum.sort()
    |> with_price_levels(state.asks)
  end

  defp with_price_levels(prices, level_details) do
    prices
    |> Enum.map(fn price ->
      {size, processed_at, server_changed_at} = level_details[price]

      %PriceLevel{
        price: price,
        size: size,
        processed_at: processed_at,
        server_changed_at: server_changed_at
      }
    end)
  end

  defp take(list, :all), do: list

  defp take(list, depth) do
    list
    |> Enum.take(depth)
  end

  defp update_side(state, side, price_levels) do
    new_side =
      state
      |> Map.get(side)
      |> Map.merge(price_levels)
      |> Map.drop(price_levels |> drop_prices)

    state
    |> Map.put(side, new_side)
  end

  defp drop_prices(price_levels) do
    price_levels
    |> Enum.filter(fn {_price, {size, _processed_at, _server_changed_at}} -> size == 0 end)
    |> Enum.map(fn {price, _} -> price end)
  end
end
