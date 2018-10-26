defmodule Tai.VenueAdapters.Binance do
  use Tai.Exchanges.Adapter

  defdelegate products(venue_id), to: Tai.VenueAdapters.Binance.Products

  defdelegate asset_balances(venue_id, account_id, credentials),
    to: Tai.VenueAdapters.Binance.AssetBalances

  defdelegate maker_taker_fees(venue_id, account_id, credentials),
    to: Tai.VenueAdapters.Binance.MakerTakerFees
end
