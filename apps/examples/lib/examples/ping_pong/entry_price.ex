defmodule Examples.PingPong.EntryPrice do
  alias Tai.Markets.Quote

  @type market_quote :: Quote.t()
  @type product :: Tai.Venues.Product.t()

  @spec calculate(market_quote, product) :: Decimal.t()
  def calculate(%Quote{asks: [inside_ask | _]}, product) do
    inside_ask.price
    |> Tai.Utils.Decimal.cast!()
    |> Decimal.sub(product.price_increment)
  end
end
