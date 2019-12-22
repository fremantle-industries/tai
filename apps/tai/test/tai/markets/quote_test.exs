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

  test ".mid_price/1 is the price between the bid and ask" do
    inside_bid = struct(PricePoint, price: 101, size: 2)
    inside_ask = struct(PricePoint, price: 102, size: 10)
    market_quote = struct(Quote, bids: [inside_bid], asks: [inside_ask])

    assert Quote.mid_price(market_quote) == {:ok, Decimal.new("101.5")}
  end

  test ".mid_price/1 returns an error when there is no inside bid" do
    inside_ask = struct(PricePoint, price: 102, size: 10)
    market_quote = struct(Quote, bids: [], asks: [inside_ask])

    assert Quote.mid_price(market_quote) == {:error, :no_inside_bid}
  end

  test ".mid_price/1 returns an error when there is no inside ask" do
    inside_bid = struct(PricePoint, price: 101, size: 2)
    market_quote = struct(Quote, bids: [inside_bid], asks: [])

    assert Quote.mid_price(market_quote) == {:error, :no_inside_ask}
  end

  test ".mid_price/1 returns an error when there is no inside_bid or inside ask" do
    market_quote = struct(Quote, bids: [], asks: [])

    assert Quote.mid_price(market_quote) == {:error, :no_inside_bid_or_ask}
  end
end
