defmodule Tai.VenueAdapters.Bitmex.Accounts do
  @type venue_id :: Tai.Venue.id()
  @type account :: Tai.Venues.Account.t()
  @type credential_id :: Tai.Venue.credential_id()
  @type credentials :: Tai.Venue.credentials()
  @type shared_error_reason :: Tai.Venues.Adapter.shared_error_reason()

  @spec accounts(venue_id, credential_id, credentials) ::
          {:ok, [account]} | {:error, shared_error_reason}
  def accounts(venue_id, credential_id, credentials) do
    with {:ok, margin, _rate_limit} <-
           credentials
           |> to_venue_credentials()
           |> ExBitmex.Rest.User.Margin.get() do
      account = build(margin, venue_id, credential_id)
      {:ok, [account]}
    else
      {:error, reason, _} -> {:error, reason}
    end
  end

  @satoshis_per_btc Decimal.new(100_000_000)
  @zero Decimal.new(0)

  def build(
        %ExBitmex.Margin{currency: "XBt", amount: amount},
        venue_id,
        credential_id
      ) do
    equity = amount |> Decimal.new() |> Decimal.div(@satoshis_per_btc) |> Decimal.reduce()

    %Tai.Venues.Account{
      venue_id: venue_id,
      credential_id: credential_id,
      asset: :btc,
      type: "default",
      equity: equity,
      free: @zero,
      locked: equity
    }
  end

  defp to_venue_credentials(credentials), do: struct!(ExBitmex.Credentials, credentials)
end
