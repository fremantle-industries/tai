defmodule Tai.ExchangeAdapters.Gdax.Account.AllBalances do
  @moduledoc """
  Fetch and normalize all balances on the GDAX account
  """

  alias Tai.{CredentialError, TimeoutError}

  def fetch do
    ExGdax.list_accounts()
    |> normalize_accounts
  end

  defp normalize_accounts({:ok, raw_accounts}) do
    accounts =
      raw_accounts
      |> Enum.reduce(%{}, &normalize_account/2)

    {:ok, accounts}
  end

  defp normalize_accounts({:error, "Invalid Passphrase" = reason, _status}) do
    {:error, %CredentialError{reason: reason}}
  end

  defp normalize_accounts({:error, "Invalid API Key" = reason, _status}) do
    {:error, %CredentialError{reason: reason}}
  end

  defp normalize_accounts({:error, "timeout" = reason}) do
    {:error, %TimeoutError{reason: reason}}
  end

  defp normalize_account(%{"currency" => raw_currency, "balance" => raw_balance}, acc) do
    with symbol <- raw_currency |> String.downcase() |> String.to_atom(),
         {:ok, balance} <- Decimal.parse(raw_balance) do
      Map.put(acc, symbol, balance)
    end
  end
end
