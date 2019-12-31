defmodule Tai.VenueAdapters.Bitmex.AssetBalances do
  def asset_balances(venue_id, credential_id, credentials) do
    with {:ok, wallet, _rate_limit} <-
           credentials
           |> to_venue_credentials()
           |> ExBitmex.Rest.User.Wallet.get() do
      balance = build(wallet, venue_id, credential_id)
      {:ok, [balance]}
    end
  end

  @satoshis_per_btc Decimal.new(100_000_000)

  def build(
        %ExBitmex.Wallet{currency: "XBt", amount: amount},
        venue_id,
        credential_id
      ) do
    free = Decimal.new(0)
    locked = amount |> Decimal.new() |> Decimal.div(@satoshis_per_btc) |> Decimal.reduce()

    %Tai.Venues.AssetBalance{
      venue_id: venue_id,
      credential_id: credential_id,
      asset: :btc,
      type: "default",
      free: free,
      locked: locked
    }
  end

  defp to_venue_credentials(credentials), do: struct!(ExBitmex.Credentials, credentials)
end
