defmodule Tai.Markets.QuoteStore do
  use Stored.Store

  def after_backend_create do
    Tai.PubSub.subscribe(:market_quote)
  end

  @topic :market_quote_store
  def after_put(market_quote) do
    @topic |> Tai.PubSub.broadcast({:after_put_market_quote, market_quote})
  end
end
