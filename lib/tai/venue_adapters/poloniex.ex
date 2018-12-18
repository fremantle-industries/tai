defmodule Tai.VenueAdapters.Poloniex do
  @behaviour Tai.Venues.Adapter

  def stream_supervisor, do: Tai.Venues.NullStreamSupervisor

  def order_book_feed, do: Tai.VenueAdapters.Poloniex.OrderBookFeed

  defdelegate products(venue_id), to: Tai.VenueAdapters.Poloniex.Products

  defdelegate asset_balances(venue_id, account_id, credentials),
    to: Tai.VenueAdapters.Poloniex.AssetBalances

  defdelegate maker_taker_fees(venue_id, account_id, credentials),
    to: Tai.VenueAdapters.Poloniex.MakerTakerFees

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
