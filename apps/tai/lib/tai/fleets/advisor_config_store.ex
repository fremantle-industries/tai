defmodule Tai.Fleets.AdvisorConfigStore do
  use Stored.Store

  def default_store_id, do: @default_id
end
