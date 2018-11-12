defmodule Tai.ExchangeAdapters.Gdax.Account.AllBalances do
  @moduledoc """
  Fetch and normalize all balances on the GDAX account
  """

  def fetch(%Tai.Exchanges.Account{} = account) do
    account.credentials
    |> ExGdax.list_accounts()
    |> normalize_accounts(account)
  end

  defp normalize_accounts({:ok, raw_accounts}, account) do
    accounts =
      raw_accounts
      |> Enum.reduce(
        %{},
        &normalize_account(&1, &2, account)
      )

    {:ok, accounts}
  end

  defp normalize_accounts({:error, "Invalid Passphrase" = reason, _status}, _) do
    {:error, %Tai.CredentialError{reason: reason}}
  end

  defp normalize_accounts({:error, "Invalid API Key" = reason, _status}, _) do
    {:error, %Tai.CredentialError{reason: reason}}
  end

  defp normalize_accounts({:error, reason, 503}, _) do
    {:error, %Tai.ServiceUnavailableError{reason: reason}}
  end

  defp normalize_accounts({:error, "timeout"}, _) do
    {:error, %Tai.TimeoutError{reason: "network request timed out"}}
  end

  defp normalize_account(
         %{"currency" => raw_currency, "available" => available, "hold" => hold},
         acc,
         account
       ) do
    asset =
      raw_currency
      |> String.downcase()
      |> String.to_atom()

    balance = %Tai.Exchanges.AssetBalance{
      exchange_id: account.exchange_id,
      account_id: account.account_id,
      asset: asset,
      free: available,
      locked: hold
    }

    Map.put(acc, asset, balance)
  end
end
