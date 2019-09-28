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

  test "records the stream of market quotes" do
    Tai.PubSub.subscribe(:market_quote_store)
    market_quote = struct(Tai.Markets.Quote, venue_id: @venue, product_symbol: @symbol)

    Tai.PubSub.broadcast(:market_quote, {:tai, market_quote})

    assert_receive {:market_quote_store_upserted, upserted_market_quote}

    assert Tai.Markets.QuoteStore.all(@test_store_id) == [market_quote]
    assert upserted_market_quote == market_quote
  end
end
