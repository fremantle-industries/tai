defmodule Tai.Exchanges.Adapters.Gdax.Price do
  alias Tai.Exchanges.Adapters.Gdax.Product

  def price(symbol) do
    symbol
    |> Product.to_product_id
    |> ExGdax.get_ticker
    |> extract_price
  end

  defp extract_price({:ok, %{"price" => price}}) do
    price
    |> Decimal.new
  end
end
