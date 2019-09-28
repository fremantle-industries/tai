defmodule Tai.VenueAdapters.Binance.Stream.ProcessOrderBookTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.Binance.Stream.ProcessOrderBook
  alias Tai.Markets.{OrderBook, PricePoint}

  @venue :venue_a
  @symbol :xbtusd
  @venue_symbol "XBTUSD"
  @product struct(Tai.Venues.Product,
             venue_id: @venue,
             symbol: @symbol,
             venue_symbol: @venue_symbol
           )

  setup do
    start_supervised!({Tai.PubSub, 1})
    start_supervised!({Tai.Events, 1})

    {:ok, book_pid} = start_supervised({OrderBook, @product})
    {:ok, store_pid} = start_supervised({ProcessOrderBook, @product})

    {:ok, %{book_pid: book_pid, store_pid: store_pid}}
  end

  test "can insert new price points into the order book", %{
    book_pid: book_pid,
    store_pid: store_pid
  } do
    Tai.Events.firehose_subscribe()

    snapshot =
      struct(OrderBook,
        venue_id: @venue,
        product_symbol: @symbol,
        bids: %{},
        asks: %{}
      )

    :ok = OrderBook.replace(snapshot)

    data = %{
      "E" => 1_569_054_255_636,
      "s" => @venue_symbol,
      "b" => [["101", "15"]],
      "a" => [["100", "11"]]
    }

    GenServer.cast(store_pid, {:update, data, Timex.now()})

    assert_receive {Tai.Event, %Tai.Events.OrderBookUpdate{} = event, :debug}
    assert event.venue_id == @venue
    assert event.symbol == @symbol

    assert {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)
    assert Enum.count(bids) == 1
    assert Enum.at(bids, 0) == %PricePoint{price: 101.0, size: 15}
    assert Enum.count(asks) == 1
    assert Enum.at(asks, 0) == %PricePoint{price: 100.0, size: 11}
  end

  test "can update existing price points in the order book", %{
    book_pid: book_pid,
    store_pid: store_pid
  } do
    Tai.Events.firehose_subscribe()

    snapshot =
      struct(OrderBook,
        venue_id: @venue,
        product_symbol: @symbol,
        bids: %{101.0 => 5},
        asks: %{100.0 => 10}
      )

    :ok = OrderBook.replace(snapshot)

    data = %{
      "E" => 1_569_054_255_636,
      "s" => @venue_symbol,
      "b" => [["101", "15"]],
      "a" => [["100", "11"]]
    }

    GenServer.cast(store_pid, {:update, data, Timex.now()})

    assert_receive {Tai.Event, %Tai.Events.OrderBookUpdate{} = event, :debug}
    assert event.venue_id == @venue
    assert event.symbol == @symbol

    assert {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)
    assert Enum.count(bids) == 1
    assert Enum.at(bids, 0) == %PricePoint{price: 101.0, size: 15}
    assert Enum.count(asks) == 1
    assert Enum.at(asks, 0) == %PricePoint{price: 100.0, size: 11}
  end

  test "can delete existing price points from the order book", %{
    book_pid: book_pid,
    store_pid: store_pid
  } do
    Tai.Events.firehose_subscribe()

    snapshot =
      struct(OrderBook,
        venue_id: @venue,
        product_symbol: @symbol,
        bids: %{101.0 => 5},
        asks: %{100.0 => 10}
      )

    :ok = OrderBook.replace(snapshot)

    data = %{
      "E" => 1_569_054_255_636,
      "s" => @venue_symbol,
      "b" => [["101", "0"]],
      "a" => [["100", "0"]]
    }

    GenServer.cast(store_pid, {:update, data, Timex.now()})

    assert_receive {Tai.Event, %Tai.Events.OrderBookUpdate{} = event, :debug}
    assert event.venue_id == @venue
    assert event.symbol == @symbol

    assert {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)
    assert Enum.count(bids) == 0
    assert Enum.count(asks) == 0
  end
end
