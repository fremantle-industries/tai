defmodule Tai.VenueAdapters.Bitmex.NormalizeAccount do
  @type margin :: ExBitmex.Margin.t()
  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type account :: Tai.Venues.Account.t()
  @type currency :: String.t()

  @satoshis_per_btc Decimal.new(100_000_000)
  @zero Decimal.new(0)

  @spec satoshis_to_btc(Decimal.t() | integer) :: Decimal.t()
  def satoshis_to_btc(satoshis) when is_integer(satoshis) do
    satoshis
    |> Decimal.new()
    |> satoshis_to_btc()
  end

  def satoshis_to_btc(satoshis) do
    satoshis
    |> Decimal.div(@satoshis_per_btc)
    |> Decimal.normalize()
  end

  @spec build(margin, venue_id, credential_id) ::
          {:ok, account} | {:error, {:unsupported_currency, currency}}
  def build(
        %ExBitmex.Margin{currency: "XBt", amount: amount},
        venue_id,
        credential_id
      ) do
    equity = satoshis_to_btc(amount)

    account = %Tai.Venues.Account{
      venue_id: venue_id,
      credential_id: credential_id,
      asset: :btc,
      type: "default",
      equity: equity,
      free: @zero,
      locked: equity
    }

    {:ok, account}
  end

  def build(margin, _, _) do
    {:error, {:unsupported_currency, margin.currency}}
  end
end
