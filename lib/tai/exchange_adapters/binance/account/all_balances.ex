defmodule Tai.ExchangeAdapters.Binance.Account.AllBalances do
  @moduledoc """
  Fetch and normalize all balances on the Binance account
  """

  def fetch(%Tai.Exchanges.Account{} = account) do
    Binance.get_account()
    |> normalize_assets(account)
  end

  defp normalize_assets({:ok, %Binance.Account{balances: raw_balances}}, account) do
    balances =
      raw_balances
      |> Enum.reduce(
        %{},
        &normalize_asset(&1, &2, account)
      )

    {:ok, balances}
  end

  defp normalize_assets(
         {:error, %{"code" => -2014, "msg" => "API-key format invalid." = reason}},
         _
       ) do
    {:error, %Tai.CredentialError{reason: reason}}
  end

  defp normalize_assets({:error, {:http_error, %HTTPoison.Error{reason: "timeout"}}}, _) do
    {:error, %Tai.TimeoutError{reason: "network request timed out"}}
  end

  defp normalize_asset(%{"asset" => raw_asset, "free" => free, "locked" => locked}, acc, account) do
    asset =
      raw_asset
      |> String.downcase()
      |> String.to_atom()

    balance = %Tai.Venues.AssetBalance{
      exchange_id: account.exchange_id,
      account_id: account.account_id,
      asset: asset,
      free: free,
      locked: locked
    }

    Map.put(acc, asset, balance)
  end
end
