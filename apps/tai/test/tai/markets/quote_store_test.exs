defmodule Tai.Markets.QuoteStoreTest do
  use Tai.TestSupport.DataCase, async: false

  @venue :venue_a
  @symbol :xbtusd

  test "broadcasts a message namespaced to the venue/product after the quote is stored" do
    Tai.Markets.subscribe_quote({@venue, @symbol})
    market_quote = struct(Tai.Markets.Quote, venue_id: @venue, product_symbol: @symbol)

    assert {:ok, _} = Tai.Markets.QuoteStore.put(market_quote)
    assert_receive %Tai.Markets.Quote{} = stored_market_quote

    market_quotes = Tai.Markets.QuoteStore.all()
    assert Enum.count(market_quotes) == 1
    assert Enum.member?(market_quotes, market_quote)
    assert stored_market_quote == market_quote
  end
end
