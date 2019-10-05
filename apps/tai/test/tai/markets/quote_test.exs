defmodule Tai.Markets.QuoteTest do
  use ExUnit.Case, async: true
  alias Tai.Markets.{PricePoint, Quote}

  test ".inside_bid/1 returns the first bid price point within the quote" do
    inside_bid = struct(PricePoint, price: 101, size: 2)
    market_quote = struct(Quote, bids: [inside_bid])

    assert Quote.inside_bid(market_quote) == inside_bid
  end

  test ".inside_ask/1 returns the first ask price point within the quote" do
    inside_ask = struct(PricePoint, price: 201, size: 10)
    market_quote = struct(Quote, asks: [inside_ask])

    assert Quote.inside_ask(market_quote) == inside_ask
  end
end
