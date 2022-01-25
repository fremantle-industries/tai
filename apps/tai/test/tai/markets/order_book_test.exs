defmodule Tai.Markets.OrderBookTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.Markets.{OrderBook, PricePoint, Quote}

  @quote_depth 2
  @venue :venue_a
  @product struct(Tai.Venues.Product, venue_id: @venue, symbol: :btc_usd)
  @broadcast_enabled_product struct(Tai.Venues.Product,
                               venue_id: :other_venue,
                               symbol: :other_symbol
                             )

  setup do
    start_supervised!(OrderBook.child_spec(@product, @quote_depth, false))
    Tai.Markets.subscribe_quote(@venue)
    :ok
  end

  describe ".replace/1" do
    test "saves the market quote from the change set" do
      last_venue_timestamp = Timex.now()
      last_received_at = System.monotonic_time()

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

      assert_receive %Quote{} = market_quote
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

      assert_receive %Quote{} = market_quote
      assert Enum.empty?(market_quote.bids)
      assert Enum.count(market_quote.asks) == 2
      assert %PricePoint{} = Enum.at(market_quote.asks, 0)
      assert %PricePoint{} = Enum.at(market_quote.asks, 1)
    end

    test "can quote a nil ask" do
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

      assert_receive %Quote{} = market_quote
      assert Enum.count(market_quote.bids) == 2
      assert %PricePoint{} = Enum.at(market_quote.bids, 0)
      assert %PricePoint{} = Enum.at(market_quote.bids, 1)
      assert Enum.empty?(market_quote.asks)
    end

    test "broadcasts change_set when enabled" do
      :ok = Tai.SystemBus.subscribe(:change_set)
      start_supervised!(OrderBook.child_spec(@broadcast_enabled_product, @quote_depth, true))

      broadcast_enabled_change_set =
        struct(OrderBook.ChangeSet,
          venue: @broadcast_enabled_product.venue_id,
          symbol: @broadcast_enabled_product.symbol,
          changes: [
            {:upsert, :bid, 100.0, 1.0},
            {:upsert, :ask, 102.0, 11.0}
          ]
        )

      OrderBook.replace(broadcast_enabled_change_set)

      assert_receive {:change_set, received_change_set}
      assert received_change_set == broadcast_enabled_change_set

      broadcast_disabled_change_set =
        struct(OrderBook.ChangeSet,
          venue: @product.venue_id,
          symbol: @product.symbol,
          changes: [
            {:upsert, :bid, 10.0, 1.0},
            {:upsert, :ask, 12.0, 11.0}
          ]
        )

      OrderBook.replace(broadcast_disabled_change_set)

      refute_receive {:change_set, _}
    end
  end

  describe ".apply/1" do
    test "saves a market quote when the change set results in a new quote after replace" do
      change_set_1 = %OrderBook.ChangeSet{
        venue: @product.venue_id,
        symbol: @product.symbol,
        last_venue_timestamp: Timex.now(),
        last_received_at: System.monotonic_time(),
        changes: [
          {:upsert, :bid, 100.0, 1.0},
          {:upsert, :ask, 102.0, 11.0}
        ]
      }

      OrderBook.replace(change_set_1)
      assert_receive %Quote{} = _

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

      assert_receive %Quote{} = market_quote_2
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

    test "saves a market quote when the change set results in a new quote after apply" do
      venue_timestamp_1 = Timex.now()
      received_at_1 = System.monotonic_time()

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

      assert_receive %Quote{} = market_quote_1
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
      received_at_2 = System.monotonic_time()

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

      assert_receive %Quote{} = market_quote_2
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
      change_set_1 = %OrderBook.ChangeSet{
        venue: @product.venue_id,
        symbol: @product.symbol,
        last_venue_timestamp: Timex.now(),
        last_received_at: System.monotonic_time(),
        changes: [
          {:upsert, :bid, 100.0, 1.0},
          {:upsert, :ask, 102.0, 11.0}
        ]
      }

      OrderBook.apply(change_set_1)
      assert_receive %Quote{} = _

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

      assert_receive %Quote{} = market_quote
      assert Enum.empty?(market_quote.bids)
      assert Enum.empty?(market_quote.asks)
    end

    test "broadcasts change_set when enabled" do
      :ok = Tai.SystemBus.subscribe(:change_set)
      start_supervised!(OrderBook.child_spec(@broadcast_enabled_product, @quote_depth, true))

      broadcast_enabled_change_set =
        struct(OrderBook.ChangeSet,
          venue: @broadcast_enabled_product.venue_id,
          symbol: @broadcast_enabled_product.symbol,
          changes: [
            {:upsert, :bid, 100.0, 1.0},
            {:upsert, :ask, 102.0, 11.0}
          ]
        )

      OrderBook.apply(broadcast_enabled_change_set)

      assert_receive {:change_set, received_change_set}
      assert received_change_set == broadcast_enabled_change_set

      broadcast_disabled_change_set =
        struct(OrderBook.ChangeSet,
          venue: @product.venue_id,
          symbol: @product.symbol,
          changes: [
            {:upsert, :bid, 10.0, 1.0},
            {:upsert, :ask, 12.0, 11.0}
          ]
        )

      OrderBook.apply(broadcast_disabled_change_set)

      refute_receive {:change_set, _}
    end
  end
end
