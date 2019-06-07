defmodule Tai.VenueAdapters.Binance do
  alias Tai.VenueAdapters.Binance.{
    StreamSupervisor,
    Products,
    AssetBalances,
    MakerTakerFees,
    CreateOrder,
    CancelOrder
  }

  @behaviour Tai.Venues.Adapter

  def stream_supervisor, do: StreamSupervisor
  def order_book_feed, do: Tai.VenueAdapters.NullOrderBookFeed
  defdelegate products(venue_id), to: Products
  defdelegate asset_balances(venue_id, account_id, credentials), to: AssetBalances
  defdelegate maker_taker_fees(venue_id, account_id, credentials), to: MakerTakerFees
  def positions(_venue_id, _account_id, _credentials), do: {:error, :not_supported}
  defdelegate create_order(order, credentials), to: CreateOrder
  def amend_order(_venue_order_id, _attrs, _credentials), do: {:error, :not_supported}
  defdelegate cancel_order(order, credentials), to: CancelOrder
end
