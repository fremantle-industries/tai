defmodule Tai.Exchanges.ConfigTest do
  use ExUnit.Case, async: true
  doctest Tai.Exchanges.Config

  test "exchanges returns the application config" do
    assert Tai.Exchanges.Config.exchanges == %{
      test_exchange_a: Tai.ExchangeAdapters.Test,
      test_exchange_b: Tai.ExchangeAdapters.Test
    }
  end

  test "exchange_ids returns the keys from exchanges" do
    assert Tai.Exchanges.Config.exchange_ids() == [:test_exchange_a, :test_exchange_b]
  end

  test "exchange_adapter returns the configured module for the exchange name" do
    assert Tai.Exchanges.Config.exchange_adapter(:test_exchange_a) == Tai.ExchangeAdapters.Test
  end

  test "order_book_feeds returns the application config" do
    assert Tai.Exchanges.Config.order_book_feeds() == %{
      test_feed_a: [
        adapter: Tai.ExchangeAdapters.Test.OrderBookFeed,
        order_books: [:btcusd, :ltcusd]
      ],
      test_feed_b: [
        adapter: Tai.ExchangeAdapters.Test.OrderBookFeed,
        order_books: [:ethusd, :ltcusd]
      ]
    }
  end

  test "order_book_feed_ids returns a list" do
    assert Tai.Exchanges.Config.order_book_feed_ids() == [:test_feed_a, :test_feed_b]
  end

  test "order_book_feed_adapters returns a map of the adapters by id" do
    assert Tai.Exchanges.Config.order_book_feed_adapters() == %{
      test_feed_a: Tai.ExchangeAdapters.Test.OrderBookFeed,
      test_feed_b: Tai.ExchangeAdapters.Test.OrderBookFeed
    }
  end

  test "order_book_feed_adapter returns the configured module for the given feed id" do
    assert Tai.Exchanges.Config.order_book_feed_adapter(:test_feed_a) == Tai.ExchangeAdapters.Test.OrderBookFeed
  end

  test "order_book_feed_symbols returns the symbols for the given feed id" do
    assert Tai.Exchanges.Config.order_book_feed_symbols(:test_feed_a) == [:btcusd, :ltcusd]
  end
end
