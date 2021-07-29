defmodule Tai.VenueAdapters.Stub do
  alias Tai.VenueAdapters.Stub.StreamSupervisor

  @behaviour Tai.Venues.Adapter

  @impl true
  def stream_supervisor, do: StreamSupervisor

  @impl true
  def products(_venue_id), do: {:error, :not_implemented}

  @impl true
  def funding_rates(_venue_id), do: {:error, :not_implemented}

  @impl true
  def accounts(_venue_id, _credential_id, _credentials), do: {:error, :not_implemented}

  @impl true
  def maker_taker_fees(_venue_id, _credential_id, _credentials), do: {:error, :not_implemented}

  @impl true
  def positions(_venue_id, _credential_id, _credentials), do: {:error, :not_implemented}

  @impl true
  def create_order(_order, _credentials), do: {:error, :not_implemented}

  @impl true
  def cancel_order(_order, _credentials), do: {:error, :not_implemented}

  @impl true
  def amend_order(_order, _attrs, _credentials), do: {:error, :not_supported}

  @impl true
  def amend_bulk_orders(_orders_with_attrs, _credentials), do: {:error, :not_supported}
end
