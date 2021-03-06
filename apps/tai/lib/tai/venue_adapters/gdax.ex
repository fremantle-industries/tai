defmodule Tai.VenueAdapters.Gdax do
  alias Tai.VenueAdapters.Gdax.{
    StreamSupervisor,
    Accounts,
    MakerTakerFees,
    Products
  }

  @behaviour Tai.Venues.Adapter

  def stream_supervisor, do: StreamSupervisor
  defdelegate products(venue_id), to: Products
  def funding_rates(_venue_id), do: {:error, :not_implemented}
  def estimated_funding_rates(_venue_id), do: {:error, :not_implemented}
  defdelegate accounts(venue_id, credential_id, credentials), to: Accounts
  defdelegate maker_taker_fees(venue_id, credential_id, credentials), to: MakerTakerFees
  def positions(_venue_id, _credential_id, _credentials), do: {:error, :not_supported}
  def create_order(_order, _credentials), do: {:error, :not_implemented}
  def amend_order(_venue_order_id, _attrs, _credentials), do: {:error, :not_implemented}
  def amend_bulk_orders(_orders_with_attrs, _credentials), do: {:error, :not_supported}
  def cancel_order(_venue_order_id, _credentials), do: {:error, :not_implemented}
end
