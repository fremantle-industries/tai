defmodule Tai.VenueAdapters.Binance do
  @behaviour Tai.Venues.Adapter

  def stream_supervisor, do: Tai.VenueAdapters.Binance.StreamSupervisor

  def order_book_feed, do: Tai.VenueAdapters.NullOrderBookFeed

  defdelegate products(venue_id), to: Tai.VenueAdapters.Binance.Products

  defdelegate asset_balances(venue_id, account_id, credentials),
    to: Tai.VenueAdapters.Binance.AssetBalances

  defdelegate maker_taker_fees(venue_id, account_id, credentials),
    to: Tai.VenueAdapters.Binance.MakerTakerFees

  def positions(_venue_id, _account_id, _credentials) do
    {:error, :not_supported}
  end

  defdelegate create_order(order, credentials), to: Tai.VenueAdapters.Binance.CreateOrder

  def amend_order(_venue_order_id, _attrs, _credentials) do
    {:error, :not_implemented}
  end

  def cancel_order(_venue_order_id, _credentials) do
    {:error, :not_implemented}
  end
end
