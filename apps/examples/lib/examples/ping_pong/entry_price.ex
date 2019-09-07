defmodule Examples.PingPong.EntryPrice do
  @type market_quote :: Tai.Markets.Quote.t()
  @type product :: Tai.Venues.Product.t()

  @spec calculate(market_quote, product) :: Decimal.t()
  def calculate(market_quote, product) do
    market_quote.ask.price
    |> Decimal.cast()
    |> Decimal.sub(product.price_increment)
  end
end
