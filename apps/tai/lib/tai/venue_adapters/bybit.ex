defmodule Tai.VenueAdapters.Bybit do
  alias Tai.VenueAdapters.Bybit.{
    StreamSupervisor,
    Products
  }

  @behaviour Tai.Venues.Adapter

  def stream_supervisor, do: StreamSupervisor
  defdelegate products(venue_id), to: Products
  def funding_rates(_venue_id), do: {:error, :not_implemented}
  def accounts(_venue_id, _credential_id, _credentials), do: {:error, :not_implemented}
  def maker_taker_fees(_venue_id, _credential_id, _credentials), do: {:error, :not_implemented}
  def positions(_venue_id, _credential_id, _credentials), do: {:error, :not_implemented}
  def create_order(_order, _credentials), do: {:error, :not_implemented}
  def amend_order(_order, _attrs, _credentials), do: {:error, :not_supported}
  def amend_bulk_orders(_orders_with_attrs, _credentials), do: {:error, :not_supported}
  def cancel_order(_order, _credentials), do: {:error, :not_implemented}
end
