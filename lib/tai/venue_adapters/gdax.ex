defmodule Tai.VenueAdapters.Gdax do
  use Tai.Exchanges.Adapter

  defdelegate products(venue_id), to: Tai.VenueAdapters.Gdax.Products

  defdelegate asset_balances(venue_id, account_id, credentials),
    to: Tai.VenueAdapters.Gdax.AssetBalances

  defdelegate maker_taker_fees(venue_id, account_id, credentials),
    to: Tai.VenueAdapters.Gdax.MakerTakerFees
end
