defmodule Tai.ExchangeAdapters.Poloniex.Account.AllBalances do
  @moduledoc """
  Fetch and normalize all balances on the Poloniex account
  """

  def fetch(account) do
    ExPoloniex.Trading.return_complete_balances()
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

  defp normalize_accounts({:error, %ExPoloniex.AuthenticationError{} = reason}, _) do
    {:error, %Tai.CredentialError{reason: reason}}
  end

  defp normalize_accounts({:error, %HTTPoison.Error{reason: "timeout"}}, _) do
    {:error, :timeout}
  end

  defp normalize_account(
         {
           raw_currency,
           %{"available" => raw_available, "onOrders" => raw_on_orders}
         },
         acc,
         account
       ) do
    asset =
      raw_currency
      |> String.downcase()
      |> String.to_atom()

    balance = %Tai.Venues.AssetBalance{
      exchange_id: account.exchange_id,
      account_id: account.account_id,
      asset: asset,
      free: raw_available,
      locked: raw_on_orders
    }

    Map.put(acc, asset, balance)
  end
end
