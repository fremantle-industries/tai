defmodule Tai.Markets.OrderBookTest do
  use ExUnit.Case, async: false
  alias Tai.Markets.{OrderBook, PricePoint}

  @product struct(Tai.Venues.Product, venue_id: :venue_a, symbol: :btc_usd)
  @topic {@product.venue_id, @product.symbol}
  @quote_depth 2

  setup do
    start_supervised!(Tai.Markets.QuoteStore)
    start_supervised!({Tai.SystemBus, 1})
    start_supervised!(OrderBook.child_spec(@product, @quote_depth, false))
    :ok
  end

  describe ".replace/1" do
    test "saves the market quote from the change set" do
      Tai.SystemBus.subscribe({:market_quote_store, @topic})
      last_venue_timestamp = Timex.now()
      last_received_at = Timex.now()

      change_set = %OrderBook.ChangeSet{
        venue: @product.venue_id,
        symbol: @product.symbol,
        last_venue_timestamp: last_venue_timestamp,
        last_received_at: last_received_at,
        changes: [
          {:upsert, :bid, 999.9, 1.1},
          {:upsert, :bid, 999.8, 1.0},
          {:upsert, :bid, 999.7, 0.3},
          {:upsert, :ask, 1000.0, 0.1},
          {:upsert, :ask, 1001.1, 0.11},
          {:upsert, :ask, 1001.3, 4.5}
        ]
      }

      OrderBook.replace(change_set)

      assert_receive {:market_quote_store, :after_put, market_quote}
      assert market_quote.last_received_at == last_received_at
      assert market_quote.last_venue_timestamp == last_venue_timestamp
      assert market_quote.product_symbol == @product.symbol
      assert market_quote.venue_id == @product.venue_id
      assert Enum.count(market_quote.asks) == 2
      assert Enum.at(market_quote.asks, 0) == %PricePoint{price: 1000.0, size: 0.1}
      assert Enum.at(market_quote.asks, 1) == %PricePoint{price: 1001.1, size: 0.11}
      assert Enum.count(market_quote.bids) == 2
      assert Enum.at(market_quote.bids, 0) == %PricePoint{price: 999.9, size: 1.1}
      assert Enum.at(market_quote.bids, 1) == %PricePoint{price: 999.8, size: 1.0}
    end

    test "can quote a nil bid" do
      Tai.SystemBus.subscribe({:market_quote_store, @topic})

      change_set =
        struct(OrderBook.ChangeSet,
          venue: @product.venue_id,
          symbol: @product.symbol,
          changes: [
            {:upsert, :ask, 101, 8},
            {:upsert, :ask, 102, 16}
          ]
        )

      OrderBook.replace(change_set)

      assert_receive {:market_quote_store, :after_put, market_quote}
      assert Enum.count(market_quote.bids) == 0
      assert Enum.count(market_quote.asks) == 2
      assert %PricePoint{} = Enum.at(market_quote.asks, 0)
      assert %PricePoint{} = Enum.at(market_quote.asks, 1)
    end

    test "can quote a nil ask" do
      Tai.SystemBus.subscribe({:market_quote_store, @topic})

      change_set =
        struct(OrderBook.ChangeSet,
          venue: @product.venue_id,
          symbol: @product.symbol,
          changes: [
            {:upsert, :bid, 300, 3},
            {:upsert, :bid, 302, 8}
          ]
        )

      OrderBook.replace(change_set)

      assert_receive {:market_quote_store, :after_put, market_quote}
      assert Enum.count(market_quote.bids) == 2
      assert %PricePoint{} = Enum.at(market_quote.bids, 0)
      assert %PricePoint{} = Enum.at(market_quote.bids, 1)
      assert Enum.count(market_quote.asks) == 0
    end

    test "broadcasts change_set when enabled" do
      Tai.SystemBus.subscribe(:change_set)
      other_product = struct(Tai.Venues.Product, venue_id: :other_venue, symbol: :other_symbol)
      start_supervised!(OrderBook.child_spec(other_product, @quote_depth, true))

      change_set_1 =
        struct(OrderBook.ChangeSet,
          venue: other_product.venue_id,
          symbol: other_product.symbol,
          changes: [
            {:upsert, :bid, 100.0, 1.0},
            {:upsert, :ask, 102.0, 11.0}
          ]
        )

      OrderBook.replace(change_set_1)

      assert_receive {:change_set, change_set_1}

      change_set_2 =
        struct(OrderBook.ChangeSet,
          venue: @product.venue_id,
          symbol: @product.symbol,
          changes: [
            {:upsert, :bid, 10.0, 1.0},
            {:upsert, :ask, 12.0, 11.0}
          ]
        )

      OrderBook.replace(change_set_2)

      refute_receive {:change_set, _}
    end
  end

  describe ".apply/1" do
    test "saves a market quote when the change set results in a new quote" do
      Tai.SystemBus.subscribe({:market_quote_store, @topic})

      venue_timestamp_1 = Timex.now()
      received_at_1 = Timex.now()

      change_set_1 = %OrderBook.ChangeSet{
        venue: @product.venue_id,
        symbol: @product.symbol,
        last_venue_timestamp: venue_timestamp_1,
        last_received_at: received_at_1,
        changes: [
          {:upsert, :bid, 100.0, 1.0},
          {:upsert, :ask, 102.0, 11.0}
        ]
      }

      OrderBook.apply(change_set_1)

      assert_receive {:market_quote_store, :after_put, market_quote_1}
      assert market_quote_1.last_venue_timestamp == venue_timestamp_1
      assert market_quote_1.last_received_at == received_at_1
      assert Enum.count(market_quote_1.bids) == 1
      assert %PricePoint{} = inside_bid_1 = Enum.at(market_quote_1.bids, 0)
      assert inside_bid_1.price == 100.0
      assert inside_bid_1.size == 1.0
      assert Enum.count(market_quote_1.asks) == 1
      assert %PricePoint{} = inside_ask_1 = Enum.at(market_quote_1.asks, 0)
      assert inside_ask_1.price == 102.0
      assert inside_ask_1.size == 11.0

      venue_timestamp_2 = Timex.now()
      received_at_2 = Timex.now()

      change_set_2 = %OrderBook.ChangeSet{
        venue: @product.venue_id,
        symbol: @product.symbol,
        last_venue_timestamp: venue_timestamp_2,
        last_received_at: received_at_2,
        changes: [
          {:upsert, :bid, 100.0, 5.0},
          {:upsert, :ask, 102.0, 7.0}
        ]
      }

      OrderBook.apply(change_set_2)

      assert_receive {:market_quote_store, :after_put, market_quote_2}
      assert market_quote_2.last_venue_timestamp == venue_timestamp_2
      assert market_quote_2.last_received_at == received_at_2
      assert Enum.count(market_quote_2.bids) == 1
      assert %PricePoint{} = inside_bid_2 = Enum.at(market_quote_2.bids, 0)
      assert inside_bid_2.price == 100.0
      assert inside_bid_2.size == 5.0
      assert Enum.count(market_quote_2.asks) == 1
      assert %PricePoint{} = inside_ask_2 = Enum.at(market_quote_2.asks, 0)
      assert inside_ask_2.price == 102.0
      assert inside_ask_2.size == 7.0

      OrderBook.apply(change_set_2)

      refute_receive {:market_quote_store, :after_put, _}
    end

    test "can delete existing bids & asks" do
      Tai.SystemBus.subscribe({:market_quote_store, @topic})

      change_set_1 = %OrderBook.ChangeSet{
        venue: @product.venue_id,
        symbol: @product.symbol,
        last_venue_timestamp: Timex.now(),
        last_received_at: Timex.now(),
        changes: [
          {:upsert, :bid, 100.0, 1.0},
          {:upsert, :ask, 102.0, 11.0}
        ]
      }

      OrderBook.apply(change_set_1)

      assert_receive {:market_quote_store, :after_put, _}

      change_set_2 =
        struct(OrderBook.ChangeSet,
          venue: @product.venue_id,
          symbol: @product.symbol,
          changes: [
            {:delete, :bid, 100.0},
            {:delete, :ask, 102.0}
          ]
        )

      OrderBook.apply(change_set_2)

      assert_receive {:market_quote_store, :after_put, market_quote}
      assert Enum.count(market_quote.bids) == 0
      assert Enum.count(market_quote.asks) == 0
    end

    test "broadcasts change_set when enabled" do
      Tai.SystemBus.subscribe(:change_set)
      other_product = struct(Tai.Venues.Product, venue_id: :other_venue, symbol: :other_symbol)
      start_supervised!(OrderBook.child_spec(other_product, @quote_depth, true))

      change_set_1 =
        struct(OrderBook.ChangeSet,
          venue: other_product.venue_id,
          symbol: other_product.symbol,
          changes: [
            {:upsert, :bid, 100.0, 1.0},
            {:upsert, :ask, 102.0, 11.0}
          ]
        )

      OrderBook.apply(change_set_1)

      assert_receive {:change_set, change_set_1}

      change_set_2 =
        struct(OrderBook.ChangeSet,
          venue: @product.venue_id,
          symbol: @product.symbol,
          changes: [
            {:upsert, :bid, 10.0, 1.0},
            {:upsert, :ask, 12.0, 11.0}
          ]
        )

      OrderBook.apply(change_set_2)

      refute_receive {:change_set, _}
    end
  end
end
