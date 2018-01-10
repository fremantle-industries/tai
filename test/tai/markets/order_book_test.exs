defmodule Tai.Markets.OrderBookTest do
  use ExUnit.Case
  doctest Tai.Markets.OrderBook

  alias Tai.Markets.OrderBook

  test "replace converts and overrides the bids & asks" do
    {:ok, pid} = OrderBook.start_link(feed_id: :test_feed, symbol: :btcusd)

    :ok = OrderBook.replace(
      pid,
      bids: [{999.9, 1.1}, {999.8, 1.0}],
      asks: [{1000.0, 0.1}, {1000.1, 0.11}]
    )

    {:ok, %{bids: bids, asks: asks}} = OrderBook.quotes(pid)
    assert bids == [
      [price: 999.9, size: 1.1],
      [price: 999.8, size: 1.0]
    ]
    assert asks == [
      [price: 1000.0, size: 0.1],
      [price: 1000.1, size: 0.11]
    ]

    :ok = GenServer.stop(pid)
  end

  test "to_name combines the module, feed id and symbol into an atom" do
    name = OrderBook.to_name(
      feed_id: :test_feed,
      symbol: :btcusd
    )

    assert name == :"Elixir.Tai.Markets.OrderBook_test_feed_btcusd"
  end

  test "update replaces the given bids and asks" do
    {:ok, pid} = OrderBook.start_link(feed_id: :test_feed, symbol: :btcusd)

    :ok = OrderBook.update(
      pid,
      [
        [side: :bid, price: 147.52, size: 10.1],
        [side: :bid, price: 147.51, size: 10.2],
        [side: :bid, price: 147.53, size: 10.3],
        [side: :ask, price: 150.01, size: 1.1],
        [side: :ask, price: 150.02, size: 1.2],
        [side: :ask, price: 150.00, size: 1.3]
      ]
    )

    {:ok, %{bids: bids, asks: asks}} = OrderBook.quotes(pid)
    assert bids == [
      [price: 147.53, size: 10.3],
      [price: 147.52, size: 10.1],
      [price: 147.51, size: 10.2]
    ]
    assert asks == [
      [price: 150.00, size: 1.3],
      [price: 150.01, size: 1.1],
      [price: 150.02, size: 1.2]
    ]

    :ok = GenServer.stop(pid)
  end

  test "update removes prices when they have a size of 0" do
    {:ok, pid} = OrderBook.start_link(feed_id: :test_feed, symbol: :btcusd)

    :ok = OrderBook.update(
      pid,
      [
        [side: :bid, price: 100.0, size: 1.0],
        [side: :bid, price: 101.0, size: 1.0],
        [side: :ask, price: 102.0, size: 1.0],
        [side: :ask, price: 103.0, size: 1.0],
      ]
    )

    {:ok, %{bids: bids, asks: asks}} = OrderBook.quotes(pid)
    assert bids == [
      [price: 101.0, size: 1.0],
      [price: 100.0, size: 1.0]
    ]
    assert asks == [
      [price: 102, size: 1.0],
      [price: 103, size: 1.0]
    ]

    :ok = OrderBook.update(
      pid,
      [
        [side: :bid, price: 100.0, size: 0.0],
        [side: :ask, price: 102.0, size: 0],
      ]
    )

    {:ok, %{bids: bids, asks: asks}} = OrderBook.quotes(pid)
    assert bids == [[price: 101.0, size: 1.0]]
    assert asks == [[price: 103.0, size: 1.0]]

    :ok = GenServer.stop(pid)
  end

  test "quotes returns a price ordered list of all bids and asks" do
    {:ok, pid} = OrderBook.start_link(feed_id: :test_feed, symbol: :btcusd)

    :ok = OrderBook.update(
      pid,
      [
        [side: :bid, price: 146.00, size: 10.1],
        [side: :bid, price: 147.51, size: 10.2],
        [side: :bid, price: 147, size: 10.3],
        [side: :ask, price: 151, size: 1.1],
        [side: :ask, price: 150.02, size: 1.2],
        [side: :ask, price: 150.00, size: 1.3]
      ]
    )

    {:ok, %{bids: bids, asks: asks}} = OrderBook.quotes(pid)

    assert bids == [
      [price: 147.51, size: 10.2],
      [price: 147, size: 10.3],
      [price: 146.00, size: 10.1]
    ]
    assert asks == [
      [price: 150.00, size: 1.3],
      [price: 150.02, size: 1.2],
      [price: 151, size: 1.1]
    ]

    :ok = GenServer.stop(pid)
  end
end
