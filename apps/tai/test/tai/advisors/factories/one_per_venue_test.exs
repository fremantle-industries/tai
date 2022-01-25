defmodule Tai.Advisors.Factories.OnePerVenueTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.Advisors.Factories.OnePerVenue

  @fleet_config struct(Tai.Fleets.FleetConfig,
    id: :fleet_a,
    advisor: MyAdvisor,
    factory: Tai.Advisors.Factories.OnePerVenue,
    market_streams: "venue_a.btc_usdt venue_a.eth_usdt venue_b.btc_usdt",
    config: %{hello: :world}
  )

  test ".advisor_configs/1 returns an advisor config for each venue in the fleet" do
    mock_product(venue_id: :venue_a, symbol: :btc_usdt)
    mock_product(venue_id: :venue_a, symbol: :eth_usdt)
    mock_product(venue_id: :venue_b, symbol: :btc_usdt)

    advisor_configs = OnePerVenue.advisor_configs(@fleet_config)

    assert length(advisor_configs) == 2
    assert %Tai.Fleets.AdvisorConfig{} = advisor_config = advisor_configs |> List.first()
    assert advisor_config.mod == MyAdvisor
    assert advisor_config.fleet_id == :fleet_a
    assert advisor_config.advisor_id == :venue_a
    assert advisor_config.config == %{hello: :world}
    assert length(advisor_config.market_stream_keys) == 2
    assert advisor_config.market_stream_keys == [venue_a: :btc_usdt, venue_a: :eth_usdt]
  end
end
