defmodule Tai.VenueAdapters.Ftx do
  alias Tai.VenueAdapters.Ftx.{
    StreamSupervisor,
    Products,
    FundingRates,
    EstimatedFundingRates,
    Accounts,
    MakerTakerFees,
    Positions,
    CreateOrder,
    CancelOrder
  }

  @behaviour Tai.Venues.Adapter

  def stream_supervisor, do: StreamSupervisor
  defdelegate products(venue_id), to: Products
  defdelegate funding_rates(venue_id), to: FundingRates
  defdelegate estimated_funding_rates(venue_id), to: EstimatedFundingRates
  defdelegate accounts(venue_id, credential_id, credentials), to: Accounts
  defdelegate maker_taker_fees(venue_id, credential_id, credentials), to: MakerTakerFees
  defdelegate positions(venue_id, credential_id, credentials), to: Positions
  defdelegate create_order(order, credentials), to: CreateOrder
  def amend_order(_order, _attrs, _credentials), do: {:error, :not_supported}
  def amend_bulk_orders(_orders_with_attrs, _credentials), do: {:error, :not_supported}
  defdelegate cancel_order(order, credentials), to: CancelOrder
end
