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

    Tai.Markets.QuoteStore.put(market_quote, @test_store_id)

    assert_receive {:after_put_market_quote, new_market_quote}
    assert Tai.Markets.QuoteStore.all(@test_store_id) == [market_quote]
    assert new_market_quote == market_quote
  end
end
