defmodule Tai.VenueAdapters.Gdax.Stream.ProcessOrderBookTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.Gdax.Stream.ProcessOrderBook
  alias Tai.Markets.{OrderBook, PricePoint}

  @product struct(Tai.Venues.Product,
             venue_id: :venue_a,
             symbol: :btc_usd,
             venue_symbol: "BTC-USD"
           )
  @topic {@product.venue_id, @product.symbol}
  @order_book_name OrderBook.to_name(@product.venue_id, @product.venue_symbol)
  @quote_depth 1

  setup do
    Process.register(self(), @order_book_name)
    {:ok, _} = Application.ensure_all_started(:tzdata)
    start_supervised!({Tai.SystemBus, 1})
    start_supervised!(Tai.Markets.QuoteStore)
    start_supervised!(OrderBook.child_spec(@product, @quote_depth, false))
    {:ok, pid} = start_supervised({ProcessOrderBook, @product})

    {:ok, %{pid: pid}}
  end

  test "can snapshot the order book", %{pid: pid} do
    Tai.SystemBus.subscribe({:market_quote_store, @topic})

    data = %{
      "bids" => [["100.0", "5.0"]],
      "asks" => [["101.0", "10.0"]]
    }

    GenServer.cast(pid, {:snapshot, data, Timex.now()})

    assert_receive {:market_quote_store, :after_put, market_quote}
    assert Enum.count(market_quote.bids) == 1
    assert Enum.at(market_quote.bids, 0) == %PricePoint{price: 100.0, size: 5.0}
    assert Enum.count(market_quote.asks) == 1
    assert Enum.at(market_quote.asks, 0) == %PricePoint{price: 101.0, size: 10.0}
  end

  test "can insert price points into the order book", %{pid: pid} do
    Tai.SystemBus.subscribe({:market_quote_store, @topic})

    data = %{
      "changes" => [
        ["buy", "100.0", "5.0"],
        ["sell", "101.0", "10.0"]
      ],
      "time" => "2019-09-22T23:45:34.836816Z"
    }

    GenServer.cast(pid, {:update, data, Timex.now()})

    assert_receive {:market_quote_store, :after_put, market_quote}
    assert Enum.count(market_quote.bids) == 1
    assert Enum.at(market_quote.bids, 0) == %PricePoint{price: 100.0, size: 5.0}
    assert Enum.count(market_quote.asks) == 1
    assert Enum.at(market_quote.asks, 0) == %PricePoint{price: 101.0, size: 10.0}
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
      "changes" => [
        ["buy", "100.0", "15.0"],
        ["sell", "101.0", "11.0"]
      ],
      "time" => "2019-09-22T23:45:34.836816Z"
    }

    GenServer.cast(pid, {:update, data, Timex.now()})

    assert_receive {:market_quote_store, :after_put, market_quote}
    assert Enum.count(market_quote.bids) == 1
    assert Enum.at(market_quote.bids, 0) == %PricePoint{price: 100.0, size: 15.0}
    assert Enum.count(market_quote.asks) == 1
    assert Enum.at(market_quote.asks, 0) == %PricePoint{price: 101.0, size: 11.0}
    assert %DateTime{} = market_quote.last_venue_timestamp
    assert %DateTime{} = market_quote.last_received_at
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
      "changes" => [
        ["buy", "100.0", "0.0"],
        ["sell", "101.0", "0"]
      ],
      "time" => "2019-09-22T23:45:34.836816Z"
    }

    GenServer.cast(pid, {:update, data, Timex.now()})

    assert_receive {:market_quote_store, :after_put, market_quote}
    assert Enum.count(market_quote.bids) == 0
    assert Enum.count(market_quote.asks) == 0
    assert %DateTime{} = market_quote.last_venue_timestamp
    assert %DateTime{} = market_quote.last_received_at
  end
end
