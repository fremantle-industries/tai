defmodule Tai.Advisors.Factories.OneForAllProducts do
  @moduledoc """
  Advisor factory for sharing all subscribed products.

  Use this to receive order book updates from all subscribed products in that group.
  """

  use Tai.Advisors.Factory

  @type fleet_config :: Tai.Fleets.FleetConfig.t()
  @type advisor_config :: Tai.Fleets.AdvisorConfig.t()

  @spec advisor_configs(fleet_config) :: [advisor_config]
  def advisor_configs(fleet) do
    config = fleet.config || %{}
    market_stream_keys = build_venue_product_keys(fleet.market_streams)

    %Tai.Fleets.AdvisorConfig{
      advisor_id: :main,
      fleet_id: fleet.id,
      mod: fleet.advisor,
      start_on_boot: fleet.start_on_boot,
      restart: fleet.restart,
      shutdown: fleet.shutdown,
      market_stream_keys: market_stream_keys,
      config: config
    }
    |> List.wrap()
  end
end
