defmodule Tai.ExchangeAdapters.Gdax.Account.Balance do
  alias Tai.{ExchangeAdapters.Gdax.Price, Markets.Currency, Markets.Symbol}

  def fetch do
    ExGdax.list_accounts()
    |> convert_to_usd
    |> Currency.sum()
  end

  defp convert_to_usd({:ok, accounts}) do
    accounts
    |> Enum.map(&convert_account_to_usd/1)
  end

  defp convert_account_to_usd(%{"currency" => "USD", "balance" => balance}) do
    balance
    |> Decimal.new()
  end

  defp convert_account_to_usd(%{"currency" => currency, "balance" => balance}) do
    balance
    |> Decimal.new()
    |> Decimal.mult(usd_price(currency))
  end

  defp usd_price(currency) do
    "#{currency}usd"
    |> Symbol.downcase()
    |> Price.fetch()
    |> case do
      {:ok, price} -> price
    end
  end
end
