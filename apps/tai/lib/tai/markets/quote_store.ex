defmodule Tai.Markets.QuoteStore do
  use Stored.Store

  def after_put(market_quote) do
    Tai.Markets.publish_quote(market_quote)
  end
end
