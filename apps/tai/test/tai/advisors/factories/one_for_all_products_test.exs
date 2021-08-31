defmodule Tai.Advisors.Factories.OneForAllProductsTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.Advisors.Factories.OneForAllProducts

  @fleet_config struct(Tai.Fleets.FleetConfig,
    id: :fleet_a,
    advisor: MyAdvisor,
    factory: OneForAllProducts,
    quotes: "venue_a.btc_usdt venue_b.etc_usdt",
    config: %{hello: :world}
  )

  test ".advisor_configs/1 returns one advisor config for all products in one fleet" do
    mock_product(venue_id: :venue_a, symbol: :btc_usdt)
    mock_product(venue_id: :venue_b, symbol: :etc_usdt)

    advisor_configs = OneForAllProducts.advisor_configs(@fleet_config)

    assert Enum.count(advisor_configs) == 1
    assert %Tai.Fleets.AdvisorConfig{} = advisor_config = advisor_configs |> List.first()
    assert advisor_config.fleet_id == :fleet_a
    assert advisor_config.advisor_id == :main
    assert advisor_config.config == %{hello: :world}
    assert Enum.count(advisor_config.quote_keys) == 2
    assert advisor_config.quote_keys == [venue_a: :btc_usdt, venue_b: :etc_usdt]
  end
end
