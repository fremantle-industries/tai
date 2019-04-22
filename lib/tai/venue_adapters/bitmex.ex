defmodule Tai.VenueAdapters.Bitmex do
  alias Tai.VenueAdapters.Bitmex.{
    StreamSupervisor,
    Products,
    AssetBalances,
    Positions,
    CreateOrder,
    AmendOrder,
    CancelOrder
  }

  @behaviour Tai.Venues.Adapter

  def stream_supervisor, do: StreamSupervisor
  def order_book_feed, do: Tai.VenueAdapters.NullOrderBookFeed
  defdelegate products(venue_id), to: Products
  defdelegate asset_balances(venue_id, account_id, credentials), to: AssetBalances
  def maker_taker_fees(_, _, _), do: {:ok, nil}
  defdelegate positions(venue_id, account_id, credentials), to: Positions
  defdelegate create_order(order, credentials), to: CreateOrder
  defdelegate amend_order(order, attrs, credentials), to: AmendOrder
  defdelegate cancel_order(order, credentials), to: CancelOrder
end
