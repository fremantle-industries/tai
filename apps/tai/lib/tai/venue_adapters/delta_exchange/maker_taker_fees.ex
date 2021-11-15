defmodule Tai.VenueAdapters.DeltaExchange.MakerTakerFees do
  def maker_taker_fees(_venue_id, _credential_id, _credentials) do
    # venue_credentials = struct!(ExDeltaExchange.Credentials, credentials)

    # with {:ok, account} <- ExDeltaExchange.Account.Show.get(venue_credentials) do
    #   maker = account.maker_fee |> Tai.Utils.Decimal.cast!()
    #   taker = account.taker_fee |> Tai.Utils.Decimal.cast!()
    #   {:ok, {maker, taker}}
    # end

    {:ok, nil}
  end
end
