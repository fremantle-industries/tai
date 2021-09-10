defmodule Tai.Advisors.Factories.OnePerProductTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.Advisors.Factories.OnePerProduct

  @fleet_config struct(Tai.Fleets.FleetConfig,
    id: :fleet_a,
    advisor: MyAdvisor,
    factory: Tai.Advisors.Factories.OnePerProduct,
    quotes: "venue_a.btc_usdt",
    config: %{hello: :world}
  )

  test ".advisor_configs/1 returns an advisor config for each product in the fleet" do
    mock_product(venue_id: :venue_a, symbol: :btc_usdt)

    advisor_configs = OnePerProduct.advisor_configs(@fleet_config)

    assert Enum.count(advisor_configs) == 1
    assert %Tai.Fleets.AdvisorConfig{} = advisor_config = advisor_configs |> List.first()
    assert advisor_config.mod == MyAdvisor
    assert advisor_config.fleet_id == :fleet_a
    assert advisor_config.advisor_id == :venue_a_btc_usdt
    assert advisor_config.config == %{hello: :world}
    assert Enum.count(advisor_config.quote_keys) == 1
    assert advisor_config.quote_keys == [venue_a: :btc_usdt]
  end
end
