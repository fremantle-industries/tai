defmodule Tai.Exchanges.Adapters.Bitstamp.Balance do
  alias Tai.Exchanges.Adapters.Bitstamp.Price
  alias Tai.Symbol

  def balance do
    ExBitstamp.balance
    |> extract_balances
    |> convert_to_usd
    |> Tai.Currency.sum
  end

  defp extract_balances({:ok, accounts}) do
    accounts
    |> Enum.reduce([], fn {key, value}, acc ->
      case String.split(key, "_") do
        [symbol, "balance"] -> [{symbol, value} | acc]
        _ -> acc
      end
    end)
  end

  defp convert_to_usd(balances) do
    balances
    |> Enum.map(&convert_balance_to_usd/1)
  end

  defp convert_balance_to_usd({"usd", balance}) do
    balance
    |> Decimal.new
  end
  defp convert_balance_to_usd({symbol, balance}) do
    balance
    |> Decimal.new
    |> Decimal.mult(symbol |> usd_price)
  end

  defp usd_price(symbol) do
    "#{symbol}usd"
    |> Symbol.downcase
    |> Price.price
    |> case do
      {:ok, price} -> price
    end
  end
end
