defmodule Examples.PingPong.EntryPrice do
  alias Tai.Markets.Quote

  @type market_quote :: Quote.t()
  @type product :: Tai.Venues.Product.t()

  @spec calculate(market_quote, product) :: Decimal.t()
  def calculate(%Quote{} = market_quote, product) do
    market_quote.ask.price
    |> Decimal.cast()
    |> Decimal.sub(product.price_increment)
  end
end
