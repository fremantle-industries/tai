defmodule Tai.Advisors.Factories.OnePerProduct do
  @moduledoc """
  Advisor factory for creating an advisor instance for each subscribed product.

  Use this to receive separate trade & order book streams for each product.
  """

  use Tai.Advisors.Factory

  @type fleet_config :: Tai.Fleets.FleetConfig.t()
  @type advisor_config :: Tai.Fleets.AdvisorConfig.t()

  @spec advisor_configs(fleet_config) :: [advisor_config]
  def advisor_configs(fleet) do
    config = fleet.config || %{}
    market_stream_keys = build_venue_product_keys(fleet.market_streams)

    market_stream_keys
    |> Enum.map(fn {venue, symbol} ->
      %Tai.Fleets.AdvisorConfig{
        advisor_id: :"#{venue}_#{symbol}",
        fleet_id: fleet.id,
        mod: fleet.advisor,
        start_on_boot: fleet.start_on_boot,
        restart: fleet.restart,
        shutdown: fleet.shutdown,
        market_stream_keys: [{venue, symbol}],
        config: config
      }
    end)
  end
end
