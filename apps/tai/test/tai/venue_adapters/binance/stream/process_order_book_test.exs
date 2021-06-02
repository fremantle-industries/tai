defmodule Tai.VenueAdapters.Binance.Stream.ProcessOrderBookTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.VenueAdapters.Binance.Stream.ProcessOrderBook
  alias Tai.Markets.{OrderBook, PricePoint}

  @product struct(Tai.Venues.Product,
             venue_id: :venue_a,
             symbol: :xbtusd,
             venue_symbol: "XBTUSD"
           )
  @topic {@product.venue_id, @product.symbol}
  @order_book_name OrderBook.to_name(@product.venue_id, @product.venue_symbol)
  @quote_depth 1

  setup do
    Process.register(self(), @order_book_name)
    start_supervised!(OrderBook.child_spec(@product, @quote_depth, false))
    {:ok, pid} = start_supervised({ProcessOrderBook, @product})

    {:ok, %{pid: pid}}
  end

  test "can insert new price points into the order book", %{pid: pid} do
    Tai.SystemBus.subscribe({:market_quote_store, @topic})

    data = %{
      "E" => 1_569_054_255_636,
      "s" => @product.venue_symbol,
      "b" => [["100", "15"]],
      "a" => [["101", "11"]]
    }

    GenServer.cast(pid, {:update, data, Timex.now()})

    assert_receive {:market_quote_store, :after_put, market_quote}
    assert Enum.count(market_quote.bids) == 1
    assert Enum.at(market_quote.bids, 0) == %PricePoint{price: 100.0, size: 15.0}
    assert Enum.count(market_quote.asks) == 1
    assert Enum.at(market_quote.asks, 0) == %PricePoint{price: 101.0, size: 11.0}
    assert %DateTime{} = market_quote.last_venue_timestamp
    assert market_quote.last_received_at != nil
  end

  test "can update existing price points in the order book", %{pid: pid} do
    Tai.SystemBus.subscribe({:market_quote_store, @topic})

    snapshot =
      struct(OrderBook.ChangeSet,
        venue: @product.venue_id,
        symbol: @product.symbol,
        changes: [
          {:upsert, :bid, 100.0, 5.0},
          {:upsert, :ask, 101.0, 10.0}
        ]
      )

    OrderBook.replace(snapshot)

    assert_receive {:market_quote_store, :after_put, _}

    data = %{
      "E" => 1_569_054_255_636,
      "s" => @product.venue_symbol,
      "b" => [["100", "15"]],
      "a" => [["101", "11"]]
    }

    GenServer.cast(pid, {:update, data, Timex.now()})

    assert_receive {:market_quote_store, :after_put, market_quote}
    assert Enum.count(market_quote.bids) == 1
    assert Enum.at(market_quote.bids, 0) == %PricePoint{price: 100.0, size: 15.0}
    assert Enum.count(market_quote.asks) == 1
    assert Enum.at(market_quote.asks, 0) == %PricePoint{price: 101.0, size: 11.0}
    assert %DateTime{} = market_quote.last_venue_timestamp
    assert market_quote.last_received_at != nil
  end

  test "can delete existing price points from the order book", %{pid: pid} do
    Tai.SystemBus.subscribe({:market_quote_store, @topic})

    snapshot =
      struct(OrderBook.ChangeSet,
        venue: @product.venue_id,
        symbol: @product.symbol,
        changes: [
          {:upsert, :bid, 100.0, 5.0},
          {:upsert, :ask, 101.0, 10.0}
        ]
      )

    OrderBook.replace(snapshot)

    assert_receive {:market_quote_store, :after_put, _}

    data = %{
      "E" => 1_569_054_255_636,
      "s" => @product.venue_symbol,
      "b" => [["100", "0"]],
      "a" => [["101", "0"]]
    }

    GenServer.cast(pid, {:update, data, Timex.now()})

    assert_receive {:market_quote_store, :after_put, market_quote}
    assert Enum.count(market_quote.bids) == 0
    assert Enum.count(market_quote.asks) == 0
    assert %DateTime{} = market_quote.last_venue_timestamp
    assert market_quote.last_received_at != nil
  end
end
