defmodule Tai.Markets.QuoteStoreTest do
  use ExUnit.Case, async: false

  @test_store_id __MODULE__
  @venue :venue_a
  @symbol :xbtusd

  setup do
    start_supervised!({Tai.PubSub, 1})
    start_supervised!({Tai.Markets.QuoteStore, id: @test_store_id})

    :ok
  end

  test "broadcasts a message namespaced to the venue/product after the quote is stored" do
    Tai.PubSub.subscribe({:market_quote_store, {@venue, @symbol}})
    market_quote = struct(Tai.Markets.Quote, venue_id: @venue, product_symbol: @symbol)

    assert {:ok, _} = Tai.Markets.QuoteStore.put(market_quote, @test_store_id)
    assert_receive {:market_quote_store, :after_put, stored_market_quote}

    market_quotes = Tai.Markets.QuoteStore.all(@test_store_id)
    assert Enum.count(market_quotes) == 1
    assert Enum.member?(market_quotes, market_quote)
    assert stored_market_quote == market_quote
  end

  test "broadcasts a message on the firehose after the quote is stored" do
    Tai.PubSub.subscribe(:market_quote_store)
    market_quote = struct(Tai.Markets.Quote, venue_id: @venue, product_symbol: @symbol)

    assert {:ok, _} = Tai.Markets.QuoteStore.put(market_quote, @test_store_id)
    assert_receive {:market_quote_store, :after_put, stored_market_quote}

    market_quotes = Tai.Markets.QuoteStore.all(@test_store_id)
    assert Enum.count(market_quotes) == 1
    assert Enum.member?(market_quotes, market_quote)
    assert stored_market_quote == market_quote
  end
end
