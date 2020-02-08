defmodule Tai.Markets.ProcessQuoteTest do
  use ExUnit.Case, async: false

  @venue :venue_a
  @symbol :xbtusd
  @product struct(Tai.Venues.Product, venue_id: @venue, symbol: @symbol)
  @order_book struct(Tai.Markets.OrderBook,
                venue_id: @venue,
                product_symbol: @symbol,
                bids: %{100.0 => 5.0, 99.0 => 7.0},
                asks: %{101.0 => 8.0, 102.0 => 16.0}
              )

  setup do
    start_supervised!({Tai.PubSub, 1})
    start_supervised!(Tai.Markets.QuoteStore)
    {:ok, pid} = start_supervised({Tai.Markets.ProcessQuote, product: @product, depth: 1})

    {:ok, %{pid: pid}}
  end

  describe "#order_book_snapshot" do
    test "saves the market quote", %{pid: pid} do
      Tai.PubSub.subscribe({:market_quote_store, {@venue, @symbol}})

      change_set_1 =
        struct(Tai.Markets.OrderBook.ChangeSet,
          last_venue_timestamp: Timex.now(),
          last_received_at: Timex.now()
        )

      GenServer.cast(pid, {:order_book_snapshot, @order_book, change_set_1})

      assert_receive {:market_quote_store, :after_put, %Tai.Markets.Quote{} = market_quote}

      assert market_quote.venue_id == @venue
      assert market_quote.product_symbol == @symbol
      assert market_quote.last_venue_timestamp == change_set_1.last_venue_timestamp
      assert market_quote.last_received_at == change_set_1.last_received_at

      assert Enum.count(market_quote.bids) == 1
      assert %Tai.Markets.PricePoint{} = inside_bid = market_quote.bids |> hd()
      assert inside_bid.price == 100.0
      assert inside_bid.size == 5.0

      assert Enum.count(market_quote.asks) == 1
      assert %Tai.Markets.PricePoint{} = inside_ask = market_quote.asks |> hd()
      assert inside_ask.price == 101.0
      assert inside_ask.size == 8.0

      change_set_2 =
        struct(Tai.Markets.OrderBook.ChangeSet,
          last_venue_timestamp: Timex.now(),
          last_received_at: Timex.now()
        )

      GenServer.cast(pid, {:order_book_snapshot, @order_book, change_set_2})

      assert_receive {:market_quote_store, :after_put, %Tai.Markets.Quote{}}
    end

    test "can quote a nil bid", %{pid: pid} do
      Tai.PubSub.subscribe({:market_quote_store, {@venue, @symbol}})
      change_set = struct(Tai.Markets.OrderBook.ChangeSet)

      order_book =
        struct(Tai.Markets.OrderBook,
          venue_id: @venue,
          product_symbol: @symbol,
          bids: %{},
          asks: %{101 => 8, 102 => 16}
        )

      GenServer.cast(pid, {:order_book_snapshot, order_book, change_set})

      assert_receive {:market_quote_store, :after_put, %Tai.Markets.Quote{} = market_quote}

      assert Enum.count(market_quote.bids) == 0

      assert Enum.count(market_quote.asks) == 1
      assert %Tai.Markets.PricePoint{} = market_quote.asks |> hd()
    end

    test "can quote a nil ask", %{pid: pid} do
      Tai.PubSub.subscribe({:market_quote_store, {@venue, @symbol}})
      change_set = struct(Tai.Markets.OrderBook.ChangeSet)

      order_book =
        struct(Tai.Markets.OrderBook,
          venue_id: @venue,
          product_symbol: @symbol,
          bids: %{100 => 5, 99 => 7},
          asks: %{}
        )

      GenServer.cast(pid, {:order_book_snapshot, order_book, change_set})

      assert_receive {:market_quote_store, :after_put, %Tai.Markets.Quote{} = market_quote}

      assert Enum.count(market_quote.bids) == 1
      assert %Tai.Markets.PricePoint{} = market_quote.bids |> hd()

      assert Enum.count(market_quote.asks) == 0
    end
  end

  describe "#order_book_apply" do
    test "publishes the inside quote when the bid or ask price points change", %{pid: pid} do
      Tai.PubSub.subscribe({:market_quote_store, {@venue, @symbol}})

      order_book_1 =
        struct(Tai.Markets.OrderBook,
          venue_id: @venue,
          product_symbol: @symbol,
          bids: %{100.0 => 5.0, 99.0 => 7.0},
          asks: %{101.0 => 8.0, 102.0 => 16.0}
        )

      change_set_1 =
        struct(Tai.Markets.OrderBook.ChangeSet,
          last_venue_timestamp: Timex.now(),
          last_received_at: Timex.now(),
          changes: [{:upsert, :bid, 100.0, 5.0}]
        )

      GenServer.cast(pid, {:order_book_apply, order_book_1, change_set_1})

      assert_receive {:market_quote_store, :after_put, %Tai.Markets.Quote{} = market_quote_1}

      assert Enum.count(market_quote_1.bids) == 1
      assert %Tai.Markets.PricePoint{} = inside_bid = market_quote_1.bids |> hd()
      assert inside_bid.price == 100.0
      assert inside_bid.size == 5.0

      assert Enum.count(market_quote_1.asks) == 1
      assert %Tai.Markets.PricePoint{} = inside_ask = market_quote_1.asks |> hd()
      assert inside_ask.price == 101.0
      assert inside_ask.size == 8.0

      order_book_2 =
        struct(Tai.Markets.OrderBook,
          venue_id: @venue,
          product_symbol: @symbol,
          bids: %{100.0 => 2.1, 99.0 => 7.0},
          asks: %{101.0 => 8.0, 102.0 => 16.0}
        )

      change_set_2 =
        struct(Tai.Markets.OrderBook.ChangeSet,
          last_venue_timestamp: Timex.now(),
          last_received_at: Timex.now(),
          changes: [{:upsert, :bid, 100.0, 2.1}]
        )

      GenServer.cast(pid, {:order_book_apply, order_book_2, change_set_2})

      assert_receive {:market_quote_store, :after_put, %Tai.Markets.Quote{} = market_quote_2}

      assert market_quote_2.last_venue_timestamp == change_set_2.last_venue_timestamp
      assert market_quote_2.last_received_at == change_set_2.last_received_at

      order_book_3 =
        struct(Tai.Markets.OrderBook,
          venue_id: @venue,
          product_symbol: @symbol,
          bids: %{50.0 => 1.0, 100.0 => 2.1, 99.0 => 7.0},
          asks: %{101.0 => 8.0, 102.0 => 16.0}
        )

      change_set_3 =
        struct(Tai.Markets.OrderBook.ChangeSet,
          last_venue_timestamp: Timex.now(),
          last_received_at: Timex.now(),
          changes: [{:upsert, :bid, 50.0, 1.0}]
        )

      GenServer.cast(pid, {:order_book_apply, order_book_3, change_set_3})

      refute_receive {:market_quote_store, :after_put, %Tai.Markets.Quote{}}
    end

    test "publishes the inside quote there is currently no quote", %{pid: pid} do
      Tai.PubSub.subscribe({:market_quote_store, {@venue, @symbol}})

      change_set =
        struct(Tai.Markets.OrderBook.ChangeSet,
          last_venue_timestamp: Timex.now(),
          last_received_at: Timex.now(),
          changes: [{:upsert, :bid, 100.1, 2.0}]
        )

      GenServer.cast(pid, {:order_book_apply, @order_book, change_set})

      assert_receive {:market_quote_store, :after_put, %Tai.Markets.Quote{}}
    end
  end
end
