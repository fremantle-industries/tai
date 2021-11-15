defmodule Tai.VenueAdapters.DeltaExchange do
  alias Tai.VenueAdapters.DeltaExchange.{
    StreamSupervisor,
    Products,
    Accounts,
    MakerTakerFees,
    # Positions,
    # CreateOrder,
    # CancelOrder
  }

  @behaviour Tai.Venues.Adapter

  def stream_supervisor, do: StreamSupervisor
  defdelegate products(venue_id), to: Products
  defdelegate accounts(venue_id, credential_id, credentials), to: Accounts
  defdelegate maker_taker_fees(venue_id, credential_id, credentials), to: MakerTakerFees
  def positions(_venue_id, _credential_id, _credentials), do: {:error, :not_implemented}
  def create_order(_order, _credentials), do: {:error, :not_implemented}
  def amend_order(_order, _attrs, _credentials), do: {:error, :not_supported}
  def amend_bulk_orders(_orders_with_attrs, _credentials), do: {:error, :not_supported}
  def cancel_order(_order, _credentials), do: {:error, :not_implemented}
end
