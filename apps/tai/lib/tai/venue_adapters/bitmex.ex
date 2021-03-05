defmodule Tai.VenueAdapters.Bitmex do
  alias Tai.VenueAdapters.Bitmex.{
    StreamSupervisor,
    Products,
    Accounts,
    Positions,
    CreateOrder,
    AmendOrder,
    AmendBulkOrders,
    CancelOrder
  }

  @behaviour Tai.Venues.Adapter

  def stream_supervisor, do: StreamSupervisor
  defdelegate products(venue_id), to: Products
  def funding_rates(_venue_id), do: {:error, :not_implemented}
  defdelegate accounts(venue_id, credential_id, credentials), to: Accounts
  def maker_taker_fees(_, _, _), do: {:ok, nil}
  defdelegate positions(venue_id, credential_id, credentials), to: Positions
  defdelegate create_order(order, credentials), to: CreateOrder
  defdelegate amend_order(order, attrs, credentials), to: AmendOrder
  defdelegate amend_bulk_orders(orders_with_attrs, credentials), to: AmendBulkOrders
  defdelegate cancel_order(order, credentials), to: CancelOrder
end
