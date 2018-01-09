defmodule Tai.ExchangeAdapters.Gdax.Product do
  alias Tai.Symbol

  def to_product_id(symbol) do
    ExGdax.list_products
    |> extract_product_ids
    |> Enum.find(&(&1 |> strip_and_downcase == Symbol.downcase(symbol)))
  end

  defp extract_product_ids({:ok, products}) do
    products
    |> Enum.map(fn(%{"id" => id}) -> id end)
  end

  defp strip_and_downcase(product_id) do
    product_id
    |> String.replace("-", "")
    |> String.downcase
  end
end
