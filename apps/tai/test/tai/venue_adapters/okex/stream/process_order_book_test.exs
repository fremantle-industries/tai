defmodule Tai.VenueAdapters.OkEx.Stream.ProcessOrderBookTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.VenueAdapters.OkEx.Stream.ProcessOrderBook
  alias Tai.Markets.{OrderBook, PricePoint, Quote}

  @product struct(Tai.Venues.Product,
             venue_id: :venue_a,
             symbol: :xbtusd,
             venue_symbol: "XBTUSD"
           )
  @order_book_name OrderBook.to_name(@product.venue_id, @product.venue_symbol)
  @quote_depth 1

  setup do
    Process.register(self(), @order_book_name)
    start_supervised!(OrderBook.child_spec(@product, @quote_depth, false))
    {:ok, pid} = start_supervised({ProcessOrderBook, @product})
    Tai.Markets.subscribe_quote(@product.venue_id)

    {:ok, %{pid: pid}}
  end

  describe "snapshot" do
    test "can snapshot the order book without liquidations", %{pid: pid} do
      data = %{
        "timestamp" => "2019-01-05T02:03:06.309Z",
        "bids" => [["100", "10", "1"]],
        "asks" => [["101", "5", "1"]]
      }

      GenServer.cast(pid, {:snapshot, data, Timex.now()})

      assert_receive %Quote{} = market_quote
      assert Enum.count(market_quote.bids) == 1
      assert Enum.at(market_quote.bids, 0) == %PricePoint{price: 100.0, size: 10.0}
      assert Enum.count(market_quote.asks) == 1
      assert Enum.at(market_quote.asks, 0) == %PricePoint{price: 101.0, size: 5.0}
    end

    test "can snapshot the order book with liquidations", %{pid: pid} do
      data = %{
        "timestamp" => "2019-01-05T02:03:06.309Z",
        "bids" => [["100", "10", "2", "1"]],
        "asks" => [["101", "5", "2", "1"]]
      }

      GenServer.cast(pid, {:snapshot, data, Timex.now()})

      assert_receive %Quote{} = market_quote
      assert Enum.count(market_quote.bids) == 1
      assert Enum.at(market_quote.bids, 0) == %PricePoint{price: 100.0, size: 10.0}
      assert Enum.count(market_quote.asks) == 1
      assert Enum.at(market_quote.asks, 0) == %PricePoint{price: 101.0, size: 5.0}
    end
  end

  describe "insert" do
    test "can insert the order book without liquidations", %{pid: pid} do
      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "110", "1"]],
        "asks" => [["111", "50", "1"]]
      }

      GenServer.cast(pid, {:update, data, Timex.now()})

      assert_receive %Quote{} = market_quote
      assert Enum.count(market_quote.bids) == 1
      assert Enum.at(market_quote.bids, 0) == %PricePoint{price: 100.0, size: 110.0}
      assert Enum.count(market_quote.asks) == 1
      assert Enum.at(market_quote.asks, 0) == %PricePoint{price: 111.0, size: 50.0}
    end

    test "can insert the order book with liquidations", %{pid: pid} do
      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "110", "2", "1"]],
        "asks" => [["111", "50", "2", "1"]]
      }

      GenServer.cast(pid, {:update, data, Timex.now()})

      assert_receive %Quote{} = market_quote
      assert Enum.count(market_quote.bids) == 1
      assert Enum.at(market_quote.bids, 0) == %PricePoint{price: 100.0, size: 110.0}
      assert Enum.count(market_quote.asks) == 1
      assert Enum.at(market_quote.asks, 0) == %PricePoint{price: 111.0, size: 50.0}
    end
  end

  describe "update" do
    test "can update the order book without liquidations", %{pid: pid} do
      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "10", "1"]],
        "asks" => [["101", "5", "1"]]
      }

      GenServer.cast(pid, {:snapshot, data, Timex.now()})

      assert_receive %Quote{} = _

      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "110", "1"]],
        "asks" => [["101", "50", "1"]]
      }

      GenServer.cast(pid, {:update, data, Timex.now()})

      assert_receive %Quote{} = market_quote
      assert Enum.count(market_quote.bids) == 1
      assert Enum.at(market_quote.bids, 0) == %PricePoint{price: 100.0, size: 110.0}
      assert Enum.count(market_quote.asks) == 1
      assert Enum.at(market_quote.asks, 0) == %PricePoint{price: 101.0, size: 50.0}
    end

    test "can update the order book with liquidations", %{pid: pid} do
      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "10", "1"]],
        "asks" => [["101", "5", "1"]]
      }

      GenServer.cast(pid, {:snapshot, data, Timex.now()})

      assert_receive %Quote{} = _

      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "110", "2", "1"]],
        "asks" => [["101", "50", "2", "1"]]
      }

      GenServer.cast(pid, {:update, data, Timex.now()})

      assert_receive %Quote{} = market_quote
      assert Enum.count(market_quote.bids) == 1
      assert Enum.at(market_quote.bids, 0) == %PricePoint{price: 100.0, size: 110.0}
      assert Enum.count(market_quote.asks) == 1
      assert Enum.at(market_quote.asks, 0) == %PricePoint{price: 101.0, size: 50.0}
    end
  end

  describe "delete" do
    test "can delete existing price points from the order book without liquidations", %{pid: pid} do
      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "10", "1"]],
        "asks" => [["101", "5", "1"]]
      }

      GenServer.cast(pid, {:snapshot, data, Timex.now()})

      assert_receive %Quote{} = _

      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "0", "1"]],
        "asks" => [["101", "0", "1"]]
      }

      GenServer.cast(pid, {:update, data, Timex.now()})

      assert_receive %Quote{} = market_quote
      assert Enum.empty?(market_quote.bids)
      assert Enum.empty?(market_quote.asks)
    end

    test "can delete existing price points from the order book with liquidations", %{pid: pid} do
      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "10", "1"]],
        "asks" => [["101", "5", "1"]]
      }

      GenServer.cast(pid, {:snapshot, data, Timex.now()})

      assert_receive %Quote{} = _

      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "0", "1", "1"]],
        "asks" => [["101", "0", "1", "1"]]
      }

      GenServer.cast(pid, {:update, data, Timex.now()})

      assert_receive %Quote{} = market_quote
      assert Enum.empty?(market_quote.bids)
      assert Enum.empty?(market_quote.asks)
    end
  end
end
