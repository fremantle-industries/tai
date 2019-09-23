defmodule Tai.VenueAdapters.Gdax do
  alias Tai.VenueAdapters.Gdax.{
    StreamSupervisor,
    AssetBalances,
    MakerTakerFees,
    Products
  }

  @behaviour Tai.Venues.Adapter

  def stream_supervisor, do: StreamSupervisor
  defdelegate products(venue_id), to: Products
  defdelegate asset_balances(venue_id, account_id, credentials), to: AssetBalances
  defdelegate maker_taker_fees(venue_id, account_id, credentials), to: MakerTakerFees
  def positions(_venue_id, _account_id, _credentials), do: {:error, :not_supported}
  def create_order(_order, _credentials), do: {:error, :not_implemented}
  def amend_order(_venue_order_id, _attrs, _credentials), do: {:error, :not_implemented}
  def cancel_order(_venue_order_id, _credentials), do: {:error, :not_implemented}
end
