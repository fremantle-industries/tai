defmodule Tai.ExchangeAdapters.New.Poloniex.AssetBalances do
  @moduledoc """
  Fetch and normalize all balances on the Poloniex account
  """

  def asset_balances(exchange_id, account_id, _credentials) do
    with {:ok, raw_accounts} <- ExPoloniex.Trading.return_complete_balances() do
      accounts =
        Enum.map(
          raw_accounts,
          &build(&1, exchange_id, account_id)
        )

      {:ok, accounts}
    else
      {:error, %ExPoloniex.AuthenticationError{} = reason} ->
        {:error, %Tai.CredentialError{reason: reason}}

      {:error, %HTTPoison.Error{reason: "timeout"}} ->
        {:error, %Tai.TimeoutError{reason: "network request timed out"}}
    end
  end

  def build(
        {raw_asset, %{"available" => raw_available, "onOrders" => raw_on_orders}},
        exchange_id,
        account_id
      ) do
    asset =
      raw_asset
      |> String.downcase()
      |> String.to_atom()

    Tai.Exchanges.AssetBalance.new(
      exchange_id,
      account_id,
      asset,
      raw_available |> Decimal.new() |> Decimal.reduce(),
      raw_on_orders |> Decimal.new() |> Decimal.reduce()
    )
  end
end
