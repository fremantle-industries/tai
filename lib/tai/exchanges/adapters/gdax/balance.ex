defmodule Tai.Exchanges.Adapters.Gdax.Balance do
  alias Tai.Exchanges.Adapters.Gdax.Price

  def balance do
    ExGdax.list_accounts
    |> convert_to_usd
    |> Tai.Currency.sum
  end

  defp convert_to_usd({:ok, accounts}) do
    accounts
    |> Enum.map(&convert_account_to_usd/1)
  end

  defp convert_account_to_usd(%{"currency" => "USD", "balance" => balance}) do
    balance
    |> Decimal.new
  end

  defp convert_account_to_usd(%{"currency" => "BTC", "balance" => balance}) do
    balance
    |> Decimal.new
    |> Decimal.mult(Price.price(:btcusd))
  end

  defp convert_account_to_usd(%{"currency" => "LTC", "balance" => balance}) do
    balance
    |> Decimal.new
    |> Decimal.mult(Price.price(:ltcusd))
  end

  defp convert_account_to_usd(%{"currency" => "ETH", "balance" => balance}) do
    balance
    |> Decimal.new
    |> Decimal.mult(Price.price(:ethusd))
  end
end
