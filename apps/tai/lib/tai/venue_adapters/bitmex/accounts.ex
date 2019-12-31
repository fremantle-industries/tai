defmodule Tai.VenueAdapters.Bitmex.Accounts do
  def accounts(venue_id, credential_id, credentials) do
    with {:ok, wallet, _rate_limit} <-
           credentials
           |> to_venue_credentials()
           |> ExBitmex.Rest.User.Wallet.get() do
      account = build(wallet, venue_id, credential_id)
      {:ok, [account]}
    end
  end

  @satoshis_per_btc Decimal.new(100_000_000)
  @zero Decimal.new(0)

  def build(
        %ExBitmex.Wallet{currency: "XBt", amount: amount},
        venue_id,
        credential_id
      ) do
    locked = amount |> Decimal.new() |> Decimal.div(@satoshis_per_btc) |> Decimal.reduce()

    %Tai.Venues.Account{
      venue_id: venue_id,
      credential_id: credential_id,
      asset: :btc,
      type: "default",
      free: @zero,
      locked: locked
    }
  end

  defp to_venue_credentials(credentials), do: struct!(ExBitmex.Credentials, credentials)
end
