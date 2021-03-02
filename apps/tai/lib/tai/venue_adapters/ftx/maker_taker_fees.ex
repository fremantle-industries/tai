defmodule Tai.VenueAdapters.Ftx.MakerTakerFees do
  def maker_taker_fees(_venue_id, _credential_id, credentials) do
    venue_credentials = struct!(ExFtx.Credentials, credentials)

    with {:ok, account} <- ExFtx.Account.Show.get(venue_credentials) do
      maker = account.maker_fee |> Tai.Utils.Decimal.cast!()
      taker = account.taker_fee |> Tai.Utils.Decimal.cast!()
      {:ok, {maker, taker}}
    end
  end
end
