defmodule Tai.Exchanges.Adapters.Bitstamp.Price do
  def price(symbol) do
    symbol
    |> ExBitstamp.ticker
    |> extract_last_price
  end

  defp extract_last_price({:ok, %{"last" => last}}) do
    {:ok, Decimal.new(last)}
  end
  defp extract_last_price({:error, message}) do
    {:error, message}
  end
end
