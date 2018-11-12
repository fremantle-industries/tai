defmodule Tai.VenueAdapters.Binance.AssetBalances do
  def asset_balances(venue_id, account_id, _credentials) do
    with {:ok, %Binance.Account{balances: raw_balances}} <- Binance.get_account() do
      balances =
        Enum.map(
          raw_balances,
          &build(&1, venue_id, account_id)
        )

      {:ok, balances}
    else
      {:error,
       %{
         "code" => -1021,
         "msg" => "Timestamp for this request is outside of the recvWindow." = reason
       }} ->
        {:error, %Tai.ApiError{reason: reason}}

      {:error, %{"code" => -2014, "msg" => "API-key format invalid." = reason}} ->
        {:error, %Tai.CredentialError{reason: reason}}

      {:error, {:http_error, %HTTPoison.Error{reason: "timeout"}}} ->
        {:error, %Tai.TimeoutError{reason: "network request timed out"}}
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

    %Tai.Exchanges.AssetBalance{
      exchange_id: venue_id,
      account_id: account_id,
      asset: asset,
      free: free |> Decimal.new() |> Decimal.reduce(),
      locked: locked |> Decimal.new() |> Decimal.reduce()
    }
  end
end
