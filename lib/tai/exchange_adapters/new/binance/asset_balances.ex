defmodule Tai.ExchangeAdapters.New.Binance.AssetBalances do
  def asset_balances(exchange_id, account_id, _credentials) do
    with {:ok, %Binance.Account{balances: raw_balances}} <- Binance.get_account() do
      balances =
        Enum.map(
          raw_balances,
          &build(&1, exchange_id, account_id)
        )

      {:ok, balances}
    else
      {:error, %{"code" => -2014, "msg" => "API-key format invalid." = reason}} ->
        {:error, %Tai.CredentialError{reason: reason}}

      {:error, {:http_error, %HTTPoison.Error{reason: "timeout"}}} ->
        {:error, %Tai.TimeoutError{reason: "network request timed out"}}
    end
  end

  defp build(
         %{"asset" => raw_asset, "free" => free, "locked" => locked},
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
      free |> Decimal.new() |> Decimal.reduce(),
      locked |> Decimal.new() |> Decimal.reduce()
    )
  end
end
