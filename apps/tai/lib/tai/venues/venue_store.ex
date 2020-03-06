defmodule Tai.Venues.VenueStore do
  use Stored.Store

  @default_store_id :default

  @spec default_store_id :: store_id
  def default_store_id, do: @default_store_id
end
