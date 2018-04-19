defmodule Tai.ExchangeAdapters.Gdax.Price do
  alias Tai.ExchangeAdapters.Gdax.Product

  def fetch(symbol) do
    symbol
    |> Product.to_product_id()
    |> ExGdax.get_ticker()
    |> extract_price
  end

  defp extract_price({:ok, %{"price" => price}}) do
    {:ok, Decimal.new(price)}
  end

  defp extract_price({:error, "NotFound", _status_code}) do
    {:error, "not found"}
  end

  defp extract_price({:error, message, _status_code}) do
    {:error, message}
  end
end
