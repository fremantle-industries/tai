defmodule Tai.Exchanges.Adapters.Gdax.Product do
  def to_product_id(symbol) do
    ExGdax.list_products
    |> extract_product_ids
    |> Enum.find(&(&1 |> strip_and_downcase == symbol |> downcase))
  end

  defp extract_product_ids({:ok, products}) do
    products
    |> Enum.map(fn(%{"id" => id}) -> id end)
  end

  def strip_and_downcase(product_id) do
    product_id
    |> String.replace("-", "")
    |> String.downcase
  end

  def downcase(symbol) do
    symbol
    |> Atom.to_string
    |> String.downcase
  end
end
