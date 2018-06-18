defmodule Tai.ExchangeAdapters.Gdax.Product do
  alias Tai.Markets.Symbol

  def to_symbol(product_id) do
    product_id
    |> strip_and_downcase
    |> String.to_atom()
  end

  def to_product_id(symbol) do
    symbol
    |> Symbol.downcase()
    |> to_normalized_product_id
  end

  def to_product_ids(symbols) do
    symbols
    |> Symbol.downcase_all()
    |> to_normalized_product_ids
  end

  defp to_normalized_product_id(normalized_symbol) do
    product_ids()
    |> Enum.find(&(normalized_symbol == strip_and_downcase(&1)))
  end

  defp to_normalized_product_ids(normalized_symbols) do
    product_ids()
    |> Enum.filter(&Enum.member?(normalized_symbols, strip_and_downcase(&1)))
  end

  defp product_ids do
    ExGdax.list_products()
    |> extract_product_ids
  end

  defp extract_product_ids({:ok, products}) do
    products
    |> Enum.map(fn %{"id" => id} -> id end)
  end

  defp strip_and_downcase(product_id) do
    product_id
    |> String.replace("-", "_")
    |> String.downcase()
  end
end
