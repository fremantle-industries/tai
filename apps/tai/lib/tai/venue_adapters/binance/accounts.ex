defmodule Tai.VenueAdapters.Binance.Accounts do
  def accounts(venue_id, credential_id, credentials) do
    venue_credentials = struct!(ExBinance.Credentials, credentials)

    with {:ok, venue_account} <- ExBinance.Private.account(venue_credentials) do
      accounts = venue_account.balances |> Enum.map(&build(&1, venue_id, credential_id))
      {:ok, accounts}
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
         %{"asset" => raw_asset, "free" => venue_free, "locked" => venue_locked},
         venue_id,
         credential_id
       ) do
    asset =
      raw_asset
      |> String.downcase()
      |> String.to_atom()

    free = venue_free |> Decimal.new() |> Decimal.normalize()
    locked = venue_locked |> Decimal.new() |> Decimal.normalize()
    equity = Decimal.add(free, locked)

    %Tai.Venues.Account{
      venue_id: venue_id,
      credential_id: credential_id,
      asset: asset,
      type: "default",
      equity: equity,
      free: free,
      locked: locked
    }
  end
end
