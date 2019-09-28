defmodule Tai.VenueAdapters.Gdax.Stream.ProcessOrderBookTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.Gdax.Stream.ProcessOrderBook
  alias Tai.Markets.{OrderBook, PricePoint}

  @venue :venue_a
  @symbol :btc_usd
  @venue_symbol "BTC-USD"
  @product struct(Tai.Venues.Product,
             venue_id: @venue,
             symbol: @symbol,
             venue_symbol: @venue_symbol
           )

  setup do
    {:ok, _} = Application.ensure_all_started(:tzdata)
    start_supervised!({Tai.PubSub, 1})
    start_supervised!({Tai.Events, 1})
    {:ok, book_pid} = start_supervised({OrderBook, @product})
    {:ok, store_pid} = start_supervised({ProcessOrderBook, @product})

    {:ok, %{book_pid: book_pid, store_pid: store_pid}}
  end

  test "can snapshot the order book", %{book_pid: book_pid, store_pid: store_pid} do
    Tai.Events.firehose_subscribe()

    data = %{
      "bids" => [["100.0", "5.0"]],
      "asks" => [["101.0", "10.0"]]
    }

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

    data = %{
      "changes" => [
        ["buy", "100.0", "5.0"],
        ["sell", "101.0", "10.0"]
      ],
      "time" => "2019-09-22T23:45:34.836816Z"
    }

    GenServer.cast(store_pid, {:update, data, Timex.now()})

    assert_receive {Tai.Event, %Tai.Events.OrderBookUpdate{} = event, :debug}
    assert event.venue_id == @venue
    assert event.symbol == @symbol

    assert {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)
    assert Enum.count(bids) == 1
    assert Enum.at(bids, 0) == %PricePoint{price: 100.0, size: 5.0}
    assert Enum.count(asks) == 1
    assert Enum.at(asks, 0) == %PricePoint{price: 101.0, size: 10.0}
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
        bids: %{100.0 => 5},
        asks: %{101.0 => 10}
      )

    :ok = OrderBook.replace(snapshot)

    data = %{
      "changes" => [
        ["buy", "100.0", "15.0"],
        ["sell", "101.0", "11.0"]
      ],
      "time" => "2019-09-22T23:45:34.836816Z"
    }

    GenServer.cast(store_pid, {:update, data, Timex.now()})

    assert_receive {Tai.Event, %Tai.Events.OrderBookUpdate{} = event, :debug}
    assert event.venue_id == @venue
    assert event.symbol == @symbol

    assert {:ok, book} = OrderBook.quotes(book_pid)
    assert Enum.count(book.bids) == 1
    assert Enum.at(book.bids, 0) == %PricePoint{price: 100.0, size: 15}
    assert Enum.count(book.asks) == 1
    assert Enum.at(book.asks, 0) == %PricePoint{price: 101.0, size: 11}
    assert %DateTime{} = book.last_venue_timestamp
    assert %DateTime{} = book.last_received_at
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
        bids: %{100.0 => 5},
        asks: %{101.0 => 10}
      )

    :ok = OrderBook.replace(snapshot)

    data = %{
      "changes" => [
        ["buy", "100.0", "0.0"],
        ["sell", "101.0", "0"]
      ],
      "time" => "2019-09-22T23:45:34.836816Z"
    }

    GenServer.cast(store_pid, {:update, data, Timex.now()})

    assert_receive {Tai.Event, %Tai.Events.OrderBookUpdate{} = event, :debug}
    assert event.venue_id == @venue
    assert event.symbol == @symbol

    assert {:ok, book} = OrderBook.quotes(book_pid)
    assert Enum.count(book.bids) == 0
    assert Enum.count(book.asks) == 0
    assert %DateTime{} = book.last_venue_timestamp
    assert %DateTime{} = book.last_received_at
  end
end
