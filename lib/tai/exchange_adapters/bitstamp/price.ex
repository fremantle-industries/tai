defmodule Tai.ExchangeAdapters.Bitstamp.Price do
  def fetch(symbol) do
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
