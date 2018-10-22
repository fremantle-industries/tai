defmodule Tai.ExchangeAdapters.New.Gdax.AssetBalances do
  def asset_balances(exchange_id, account_id, credentials) do
    with {:ok, raw_accounts} <- ExGdax.list_accounts(credentials) do
      accounts =
        Enum.map(
          raw_accounts,
          &build(&1, exchange_id, account_id)
        )

      {:ok, accounts}
    else
      {:error, "Invalid Passphrase" = reason, _status} ->
        {:error, %Tai.CredentialError{reason: reason}}

      {:error, "Invalid API Key" = reason, _status} ->
        {:error, %Tai.CredentialError{reason: reason}}

      {:error, reason, 503} ->
        {:error, %Tai.ServiceUnavailableError{reason: reason}}

      {:error, "timeout"} ->
        {:error, %Tai.TimeoutError{reason: "network request timed out"}}
    end
  end

  def build(
        %{"currency" => raw_currency, "available" => available, "hold" => hold},
        exchange_id,
        account_id
      ) do
    asset =
      raw_currency
      |> String.downcase()
      |> String.to_atom()

    Tai.Exchanges.AssetBalance.new(
      exchange_id,
      account_id,
      asset,
      available |> Decimal.new() |> Decimal.reduce(),
      hold |> Decimal.new() |> Decimal.reduce()
    )
  end
end
