defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessOrderBookTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessOrderBook
  alias Tai.Markets.{OrderBook, PricePoint}

  @venue :venue_a
  @symbol :xbtusd
  @venue_symbol "XBTUSD"

  setup do
    start_supervised!(Tai.PubSub)
    start_supervised!({Tai.Events, 1})

    {:ok, book_pid} = start_supervised({OrderBook, [venue: @venue, symbol: @symbol]})

    {:ok, store_pid} =
      start_supervised(
        {ProcessOrderBook, [venue_id: @venue, symbol: @symbol, venue_symbol: @venue_symbol]}
      )

    {:ok, %{book_pid: book_pid, store_pid: store_pid}}
  end

  test "can snapshot the order book", %{book_pid: book_pid, store_pid: store_pid} do
    Tai.Events.firehose_subscribe()

    data = [
      %{"id" => "a", "price" => 101, "side" => "Sell", "size" => 10},
      %{"id" => "b", "price" => 100, "side" => "Buy", "size" => 5}
    ]

    GenServer.cast(store_pid, {:snapshot, data, Timex.now()})

    assert_receive {Tai.Event, %Tai.Events.OrderBookSnapshot{} = event, :debug}
    assert event.venue_id == @venue
    assert event.symbol == @symbol

    assert {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)
    assert Enum.count(bids) == 1
    assert Enum.at(bids, 0) == %PricePoint{price: 100, size: 5}
    assert Enum.count(asks) == 1
    assert Enum.at(asks, 0) == %PricePoint{price: 101, size: 10}
  end

  test "can insert price points into the order book", %{book_pid: book_pid, store_pid: store_pid} do
    Tai.Events.firehose_subscribe()

    data = [
      %{"id" => "a", "price" => 101, "side" => "Sell", "size" => 10},
      %{"id" => "b", "price" => 100, "side" => "Buy", "size" => 5}
    ]

    GenServer.cast(store_pid, {:insert, data, Timex.now()})

    assert_receive {Tai.Event, %Tai.Events.OrderBookUpdate{} = event, :debug}
    assert event.venue_id == @venue
    assert event.symbol == @symbol

    assert {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)
    assert Enum.count(bids) == 1
    assert Enum.at(bids, 0) == %PricePoint{price: 100, size: 5}
    assert Enum.count(asks) == 1
    assert Enum.at(asks, 0) == %PricePoint{price: 101, size: 10}
  end

  test "can update existing price points in the order book", %{
    book_pid: book_pid,
    store_pid: store_pid
  } do
    Tai.Events.firehose_subscribe()

    data = [
      %{"id" => "a", "price" => 101, "side" => "Sell", "size" => 10},
      %{"id" => "b", "price" => 100, "side" => "Buy", "size" => 5}
    ]

    GenServer.cast(store_pid, {:snapshot, data, Timex.now()})

    data = [
      %{"id" => "a", "side" => "Sell", "size" => 11},
      %{"id" => "b", "side" => "Buy", "size" => 15}
    ]

    GenServer.cast(store_pid, {:update, data, Timex.now()})

    assert_receive {Tai.Event, %Tai.Events.OrderBookUpdate{} = event, :debug}
    assert event.venue_id == @venue
    assert event.symbol == @symbol

    assert {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)
    assert Enum.count(bids) == 1
    assert Enum.at(bids, 0) == %PricePoint{price: 100, size: 15}
    assert Enum.count(asks) == 1
    assert Enum.at(asks, 0) == %PricePoint{price: 101, size: 11}
  end

  test "can delete existing price points from the order book", %{
    book_pid: book_pid,
    store_pid: store_pid
  } do
    Tai.Events.firehose_subscribe()

    data = [
      %{"id" => "a", "price" => 101, "side" => "Sell", "size" => 10},
      %{"id" => "b", "price" => 100, "side" => "Buy", "size" => 5}
    ]

    GenServer.cast(store_pid, {:snapshot, data, Timex.now()})

    data = [
      %{"id" => "a", "side" => "Sell"},
      %{"id" => "b", "side" => "Buy"}
    ]

    GenServer.cast(store_pid, {:delete, data, Timex.now()})

    assert_receive {Tai.Event, %Tai.Events.OrderBookUpdate{} = event, :debug}
    assert event.venue_id == @venue
    assert event.symbol == @symbol

    assert {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)
    assert Enum.count(bids) == 0
    assert Enum.count(asks) == 0
  end
end
