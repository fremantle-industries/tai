defmodule Tai.Advisors.Factory do
  @type fleet_config :: Tai.Fleets.FleetConfig.t()
  @type advisor_config :: Tai.Fleets.AdvisorConfig.t()

  @callback advisor_configs(fleet_config) :: [advisor_config]
end
