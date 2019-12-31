defmodule Tai.VenueAdapters.Gdax.MakerTakerFees do
  # TODO:
  # When API endpoint is added for user fee rate it should be used to get
  # an accurate value for the 30 day trailing fee rate. Currently it assumes
  # the highest taker fee rate of 0.30%.
  def maker_taker_fees(_venue_id, _credential_id, _credentials) do
    maker = Decimal.new(0)
    taker = Decimal.new("0.003")

    {:ok, {maker, taker}}
  end
end
