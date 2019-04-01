defmodule Tai.AdvisorGroups do
  @type config :: Tai.Config.t()
  @type advisor_spec :: {atom, [group_id: atom, advisor_id: atom, order_books: map, store: map]}
  @type product :: Tai.Venues.Product.t()

  defdelegate parse_config(config), to: Tai.AdvisorGroups.ParseConfig
  defdelegate build_specs(config), to: Tai.AdvisorGroups.BuildSpecs
  defdelegate build_specs(config, products), to: Tai.AdvisorGroups.BuildSpecs
  defdelegate build_specs_for_group(config, group_id), to: Tai.AdvisorGroups.BuildSpecsForGroup

  defdelegate build_specs_for_group(config, group_id, products),
    to: Tai.AdvisorGroups.BuildSpecsForGroup

  defdelegate build_specs_for_advisor(config, group_id, advisor_id),
    to: Tai.AdvisorGroups.BuildSpecsForAdvisor

  defdelegate build_specs_for_advisor(config, group_id, advisor_id, products),
    to: Tai.AdvisorGroups.BuildSpecsForAdvisor
end
