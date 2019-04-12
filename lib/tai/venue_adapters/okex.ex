defmodule Tai.VenueAdapters.OkEx do
  @behaviour Tai.Venues.Adapter

  def stream_supervisor, do: Tai.VenueAdapters.OkEx.StreamSupervisor

  def order_book_feed, do: Tai.VenueAdapters.NullOrderBookFeed

  defdelegate products(venue_id), to: Tai.VenueAdapters.OkEx.Products

  defdelegate asset_balances(venue_id, account_id, credentials),
    to: Tai.VenueAdapters.OkEx.AssetBalances

  defdelegate maker_taker_fees(venue_id, account_id, credentials),
    to: Tai.VenueAdapters.OkEx.MakerTakerFees

  def positions(_venue_id, _account_id, _credentials) do
    {:error, :not_supported}
  end

  def create_order(%Tai.Trading.Order{} = _order, _credentials) do
    {:error, :not_implemented}
  end

  def amend_order(_venue_order_id, _attrs, _credentials) do
    {:error, :not_implemented}
  end

  def cancel_order(_venue_order_id, _credentials) do
    {:error, :not_implemented}
  end
end
