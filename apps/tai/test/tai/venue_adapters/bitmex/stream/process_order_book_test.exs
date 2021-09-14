defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessOrderBookTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessOrderBook
  alias Tai.Markets.{OrderBook, PricePoint, Quote}

  @last_received_at System.monotonic_time()
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

  test "can snapshot the order book", %{pid: pid} do
    data = [
      %{"id" => "a", "price" => 101, "side" => "Sell", "size" => 10},
      %{"id" => "b", "price" => 100, "side" => "Buy", "size" => 5}
    ]

    GenServer.cast(pid, {:snapshot, data, @last_received_at})

    assert_receive %Quote{} = market_quote
    assert Enum.count(market_quote.bids) == 1
    assert Enum.at(market_quote.bids, 0) == %PricePoint{price: 100, size: 5}
    assert Enum.count(market_quote.asks) == 1
    assert Enum.at(market_quote.asks, 0) == %PricePoint{price: 101, size: 10}
    assert market_quote.last_venue_timestamp == nil
    assert market_quote.last_received_at == @last_received_at
  end

  test "can insert price points into the order book", %{pid: pid} do
    data = [
      %{"id" => "a", "price" => 101, "side" => "Sell", "size" => 10},
      %{"id" => "b", "price" => 100, "side" => "Buy", "size" => 5}
    ]

    GenServer.cast(pid, {:insert, data, @last_received_at})

    assert_receive %Quote{} = market_quote
    assert Enum.count(market_quote.bids) == 1
    assert Enum.at(market_quote.bids, 0) == %PricePoint{price: 100, size: 5}
    assert Enum.count(market_quote.asks) == 1
    assert Enum.at(market_quote.asks, 0) == %PricePoint{price: 101, size: 10}
    assert market_quote.last_venue_timestamp == nil
    assert market_quote.last_received_at == @last_received_at
  end

  test "can update existing price points in the order book", %{pid: pid} do
    data = [
      %{"id" => "a", "price" => 101, "side" => "Sell", "size" => 10},
      %{"id" => "b", "price" => 100, "side" => "Buy", "size" => 5}
    ]

    GenServer.cast(pid, {:snapshot, data, Timex.now()})

    assert_receive %Quote{} = _

    data = [
      %{"id" => "a", "side" => "Sell", "size" => 11},
      %{"id" => "b", "side" => "Buy", "size" => 15}
    ]

    GenServer.cast(pid, {:update, data, @last_received_at})

    assert_receive %Quote{} = market_quote
    assert Enum.count(market_quote.bids) == 1
    assert Enum.at(market_quote.bids, 0) == %PricePoint{price: 100, size: 15}
    assert Enum.count(market_quote.asks) == 1
    assert Enum.at(market_quote.asks, 0) == %PricePoint{price: 101, size: 11}
    assert market_quote.last_venue_timestamp == nil
    assert market_quote.last_received_at == @last_received_at
  end

  test "can delete existing price points from the order book", %{pid: pid} do
    data = [
      %{"id" => "a", "price" => 101, "side" => "Sell", "size" => 10},
      %{"id" => "b", "price" => 100, "side" => "Buy", "size" => 5}
    ]

    GenServer.cast(pid, {:snapshot, data, Timex.now()})

    assert_receive %Quote{} = _

    data = [
      %{"id" => "a", "side" => "Sell"},
      %{"id" => "b", "side" => "Buy"}
    ]

    GenServer.cast(pid, {:delete, data, @last_received_at})

    assert_receive %Quote{} = market_quote
    assert Enum.empty?(market_quote.bids)
    assert Enum.empty?(market_quote.asks)
    assert market_quote.last_venue_timestamp == nil
    assert market_quote.last_received_at == @last_received_at
  end
end
