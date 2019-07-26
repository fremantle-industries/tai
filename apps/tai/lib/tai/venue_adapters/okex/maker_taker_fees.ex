defmodule Tai.VenueAdapters.OkEx.MakerTakerFees do
  def maker_taker_fees(_venue_id, _account_id, _credentials) do
    maker = Decimal.new("0.0002")
    taker = Decimal.new("0.0003")
    {:ok, {maker, taker}}
  end
end
