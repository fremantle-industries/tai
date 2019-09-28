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
    {:ok, pid} = start_supervised({Tai.Markets.ProcessQuote, @product})

    {:ok, %{pid: pid}}
  end

  describe "#order_book_snapshot" do
    test "publishes the inside quote on an unscoped channel", %{pid: pid} do
      Tai.PubSub.subscribe(:market_quote)

      change_set_1 =
        struct(Tai.Markets.OrderBook.ChangeSet,
          last_venue_timestamp: Timex.now(),
          last_received_at: Timex.now()
        )

      GenServer.cast(pid, {:order_book_snapshot, @order_book, change_set_1})

      assert_receive {:tai, %Tai.Markets.Quote{} = market_quote}

      assert market_quote.venue_id == @venue
      assert market_quote.product_symbol == @symbol
      assert market_quote.last_venue_timestamp == change_set_1.last_venue_timestamp
      assert market_quote.last_received_at == change_set_1.last_received_at
      assert market_quote.bid.price == 100.0
      assert market_quote.bid.size == 5.0
      assert market_quote.ask.price == 101.0
      assert market_quote.ask.size == 8.0

      change_set_2 =
        struct(Tai.Markets.OrderBook.ChangeSet,
          last_venue_timestamp: Timex.now(),
          last_received_at: Timex.now()
        )

      GenServer.cast(pid, {:order_book_snapshot, @order_book, change_set_2})

      assert_receive {:tai, %Tai.Markets.Quote{}}
    end

    test "publishes the inside quote on a scoped channel", %{pid: pid} do
      Tai.PubSub.subscribe({:market_quote, @venue, @symbol})
      change_set = struct(Tai.Markets.OrderBook.ChangeSet)

      GenServer.cast(pid, {:order_book_snapshot, @order_book, change_set})

      assert_receive {:tai, %Tai.Markets.Quote{}}
    end

    test "can quote a nil bid", %{pid: pid} do
      Tai.PubSub.subscribe({:market_quote, @venue, @symbol})
      change_set = struct(Tai.Markets.OrderBook.ChangeSet)

      order_book =
        struct(Tai.Markets.OrderBook,
          venue_id: @venue,
          product_symbol: @symbol,
          bids: %{},
          asks: %{101 => 8, 102 => 16}
        )

      GenServer.cast(pid, {:order_book_snapshot, order_book, change_set})

      assert_receive {:tai, %Tai.Markets.Quote{} = market_quote}
      assert market_quote.bid == nil
      assert %Tai.Markets.PricePoint{} = market_quote.ask
    end

    test "can quote a nil ask", %{pid: pid} do
      Tai.PubSub.subscribe({:market_quote, @venue, @symbol})
      change_set = struct(Tai.Markets.OrderBook.ChangeSet)

      order_book =
        struct(Tai.Markets.OrderBook,
          venue_id: @venue,
          product_symbol: @symbol,
          bids: %{100 => 5, 99 => 7},
          asks: %{}
        )

      GenServer.cast(pid, {:order_book_snapshot, order_book, change_set})

      assert_receive {:tai, %Tai.Markets.Quote{} = market_quote}
      assert %Tai.Markets.PricePoint{} = market_quote.bid
      assert market_quote.ask == nil
    end
  end

  describe "#order_book_apply" do
    test "publishes the inside quote when the bid or ask price points change", %{pid: pid} do
      Tai.PubSub.subscribe({:market_quote, @venue, @symbol})

      change_set_1 =
        struct(Tai.Markets.OrderBook.ChangeSet,
          last_venue_timestamp: Timex.now(),
          last_received_at: Timex.now(),
          changes: [{:upsert, :bid, 100.0, 2.0}]
        )

      GenServer.cast(pid, {:order_book_apply, @order_book, change_set_1})

      assert_receive {:tai, %Tai.Markets.Quote{} = market_quote}

      assert market_quote.venue_id == @venue
      assert market_quote.product_symbol == @symbol
      assert market_quote.last_venue_timestamp == change_set_1.last_venue_timestamp
      assert market_quote.last_received_at == change_set_1.last_received_at
      assert market_quote.bid.price == 100.0
      assert market_quote.bid.size == 5.0
      assert market_quote.ask.price == 101.0
      assert market_quote.ask.size == 8.0

      change_set_2 =
        struct(Tai.Markets.OrderBook.ChangeSet,
          last_venue_timestamp: Timex.now(),
          last_received_at: Timex.now()
        )

      GenServer.cast(pid, {:order_book_apply, @order_book, change_set_2})

      refute_receive {:tai, %Tai.Markets.Quote{}}
    end

    test "publishes the inside quote there is currently no quote", %{pid: pid} do
      Tai.PubSub.subscribe({:market_quote, @venue, @symbol})

      change_set =
        struct(Tai.Markets.OrderBook.ChangeSet,
          last_venue_timestamp: Timex.now(),
          last_received_at: Timex.now(),
          changes: [{:upsert, :bid, 100.1, 2.0}]
        )

      GenServer.cast(pid, {:order_book_apply, @order_book, change_set})

      assert_receive {:tai, %Tai.Markets.Quote{} = market_quote}
    end
  end
end
