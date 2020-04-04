defmodule Tai.Commander.Markets do
  @type market_quote :: Tai.Markets.Quote.t()

  @spec get :: [market_quote]
  def get do
    Tai.Markets.QuoteStore.all()
    |> Enum.sort(&(&1.product_symbol >= &2.product_symbol))
    |> Enum.sort(&(&1.venue_id >= &2.venue_id))
  end
end
