defmodule Tai.VenueAdapters.OkEx.Stream.ProcessOrderBookTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.OkEx.Stream.ProcessOrderBook
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

  describe "snapshot" do
    test "can snapshot the order book without liquidations", %{
      book_pid: book_pid,
      store_pid: store_pid
    } do
      Tai.Events.firehose_subscribe()

      data = %{
        "timestamp" => "2019-01-05T02:03:06.309Z",
        "bids" => [["100", "10", "1"]],
        "asks" => [["101", "5", "1"]]
      }

      GenServer.cast(store_pid, {:snapshot, data, Timex.now()})

      assert_receive {Tai.Event, %Tai.Events.OrderBookSnapshot{} = event, :debug}
      assert event.venue_id == @venue
      assert event.symbol == @symbol

      assert {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)
      assert Enum.count(bids) == 1
      assert Enum.at(bids, 0) == %PricePoint{price: 100.0, size: 10.0}
      assert Enum.count(asks) == 1
      assert Enum.at(asks, 0) == %PricePoint{price: 101, size: 5}
    end

    test "can snapshot the order book with liquidations", %{
      book_pid: book_pid,
      store_pid: store_pid
    } do
      Tai.Events.firehose_subscribe()

      data = %{
        "timestamp" => "2019-01-05T02:03:06.309Z",
        "bids" => [["100", "10", "0", "1"]],
        "asks" => [["101", "5", "0", "1"]]
      }

      GenServer.cast(store_pid, {:snapshot, data, Timex.now()})

      assert_receive {Tai.Event, %Tai.Events.OrderBookSnapshot{} = event, :debug}
      assert event.venue_id == @venue
      assert event.symbol == @symbol

      assert {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)
      assert Enum.count(bids) == 1
      assert Enum.at(bids, 0) == %PricePoint{price: 100.0, size: 10.0}
      assert Enum.count(asks) == 1
      assert Enum.at(asks, 0) == %PricePoint{price: 101, size: 5}
    end
  end

  describe "insert" do
    test "can insert the order book without liquidations", %{
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
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "110", "1"]],
        "asks" => [["111", "50", "1"]]
      }

      GenServer.cast(store_pid, {:update, data, Timex.now()})

      assert_receive {Tai.Event, %Tai.Events.OrderBookUpdate{} = event, :debug}

      assert {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)
      assert Enum.count(bids) == 1
      assert Enum.at(bids, 0) == %PricePoint{price: 100.0, size: 110.0}
      assert Enum.count(asks) == 1
      assert Enum.at(asks, 0) == %PricePoint{price: 111.0, size: 50.0}
    end

    test "can insert the order book with liquidations", %{
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
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "110", "1"]],
        "asks" => [["111", "50", "1"]]
      }

      GenServer.cast(store_pid, {:update, data, Timex.now()})

      assert_receive {Tai.Event, %Tai.Events.OrderBookUpdate{} = event, :debug}

      assert {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)
      assert Enum.count(bids) == 1
      assert Enum.at(bids, 0) == %PricePoint{price: 100.0, size: 110.0}
      assert Enum.count(asks) == 1
      assert Enum.at(asks, 0) == %PricePoint{price: 111.0, size: 50.0}
    end
  end

  describe "update" do
    test "can update the order book without liquidations", %{
      book_pid: book_pid,
      store_pid: store_pid
    } do
      Tai.Events.firehose_subscribe()

      snapshot =
        struct(OrderBook,
          venue_id: @venue,
          product_symbol: @symbol,
          bids: %{100.0 => 10},
          asks: %{101.0 => 5}
        )

      :ok = OrderBook.replace(snapshot)

      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "110", "1"]],
        "asks" => [["111", "50", "1"]]
      }

      GenServer.cast(store_pid, {:update, data, Timex.now()})

      assert_receive {Tai.Event, %Tai.Events.OrderBookUpdate{} = event, :debug}

      assert {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)
      assert Enum.count(bids) == 1
      assert Enum.at(bids, 0) == %PricePoint{price: 100.0, size: 110.0}
      assert Enum.count(asks) == 2
      assert Enum.at(asks, 0) == %PricePoint{price: 101, size: 5}
      assert Enum.at(asks, 1) == %PricePoint{price: 111, size: 50}
    end

    test "can update the order book with liquidations", %{
      book_pid: book_pid,
      store_pid: store_pid
    } do
      Tai.Events.firehose_subscribe()

      snapshot =
        struct(OrderBook,
          venue_id: @venue,
          product_symbol: @symbol,
          bids: %{100.0 => 10},
          asks: %{101.0 => 5}
        )

      :ok = OrderBook.replace(snapshot)

      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "110", "1"]],
        "asks" => [["111", "50", "1"]]
      }

      GenServer.cast(store_pid, {:update, data, Timex.now()})

      assert_receive {Tai.Event, %Tai.Events.OrderBookUpdate{} = event, :debug}

      assert {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)
      assert Enum.count(bids) == 1
      assert Enum.at(bids, 0) == %PricePoint{price: 100.0, size: 110.0}
      assert Enum.count(asks) == 2
      assert Enum.at(asks, 0) == %PricePoint{price: 101, size: 5}
      assert Enum.at(asks, 1) == %PricePoint{price: 111, size: 50}
    end
  end
end
