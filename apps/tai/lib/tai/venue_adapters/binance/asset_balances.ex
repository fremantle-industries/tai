defmodule Tai.VenueAdapters.Binance.AssetBalances do
  def asset_balances(venue_id, account_id, credentials) do
    venue_credentials = struct!(ExBinance.Credentials, credentials)

    with {:ok, account} <- ExBinance.Private.account(venue_credentials) do
      balances = account.balances |> Enum.map(&build(&1, venue_id, account_id))
      {:ok, balances}
    else
      {:error, :receive_window} = error ->
        error

      {:error, {:binance_error, %{"code" => -2014, "msg" => "API-key format invalid." = reason}}} ->
        {:error, {:credentials, reason}}

      {:error, {:http_error, %HTTPoison.Error{reason: "timeout"}}} ->
        {:error, :timeout}
    end
  end

  defp build(
         %{"asset" => raw_asset, "free" => free, "locked" => locked},
         venue_id,
         account_id
       ) do
    asset =
      raw_asset
      |> String.downcase()
      |> String.to_atom()

    %Tai.Venues.AssetBalance{
      venue_id: venue_id,
      account_id: account_id,
      asset: asset,
      type: "default",
      free: free |> Decimal.new() |> Decimal.reduce(),
      locked: locked |> Decimal.new() |> Decimal.reduce()
    }
  end
end
