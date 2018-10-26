defmodule Tai.VenueAdapters.Poloniex do
  use Tai.Exchanges.Adapter

  defdelegate products(venue_id), to: Tai.VenueAdapters.Poloniex.Products

  defdelegate asset_balances(venue_id, account_id, credentials),
    to: Tai.VenueAdapters.Poloniex.AssetBalances

  defdelegate maker_taker_fees(venue_id, account_id, credentials),
    to: Tai.VenueAdapters.Poloniex.MakerTakerFees
end
