defmodule Tai.Fleets.FleetConfigStore do
  use Stored.Store

  def default_store_id, do: @default_id
end
