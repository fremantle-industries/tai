defmodule Tai.Advisors.Factories.OnePerVenue do
  @moduledoc """
  Advisor factory for creating an advisor instance per venue.

  Use this to receive trade & order book streams for products within a venue.
  """

  use Tai.Advisors.Factory

  @type fleet_config :: Tai.Fleets.FleetConfig.t()
  @type advisor_config :: Tai.Fleets.AdvisorConfig.t()

  @spec advisor_configs(fleet_config) :: [advisor_config]
  def advisor_configs(fleet) do
    config = fleet.config || %{}
    market_stream_keys = build_venue_product_keys(fleet.market_streams)

    market_stream_keys
    |> Enum.group_by(fn {v, _s} -> v end)
    |> Enum.map(fn {v, market_stream_keys} ->
      %Tai.Fleets.AdvisorConfig{
        advisor_id: v,
        fleet_id: fleet.id,
        mod: fleet.advisor,
        start_on_boot: fleet.start_on_boot,
        restart: fleet.restart,
        shutdown: fleet.shutdown,
        market_stream_keys: market_stream_keys,
        config: config
      }
    end)
  end
end
