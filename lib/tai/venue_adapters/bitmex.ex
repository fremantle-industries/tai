defmodule Tai.VenueAdapters.Bitmex do
  @behaviour Tai.Venues.Adapter

  def stream_supervisor, do: Tai.VenueAdapters.Bitmex.StreamSupervisor

  def order_book_feed, do: Tai.VenueAdapters.NullOrderBookFeed

  defdelegate products(venue_id), to: Tai.VenueAdapters.Bitmex.Products

  defdelegate asset_balances(venue_id, account_id, credentials),
    to: Tai.VenueAdapters.Bitmex.AssetBalances

  def maker_taker_fees(_, _, _), do: {:ok, nil}

  defdelegate positions(venue_id, account_id, credentials), to: Tai.VenueAdapters.Bitmex.Positions

  defdelegate create_order(order, credentials), to: Tai.VenueAdapters.Bitmex.CreateOrder

  defdelegate amend_order(venue_order_id, attrs, credentials),
    to: Tai.VenueAdapters.Bitmex.AmendOrder

  defdelegate cancel_order(venue_order_id, credentials), to: Tai.VenueAdapters.Bitmex.CancelOrder
end
