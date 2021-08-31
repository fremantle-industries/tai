defmodule Tai.Fleets.LoadTest do
  use Tai.TestSupport.DataCase, async: false

  defmodule TestConfig do
    defstruct ~w[my_product]a
  end

  test "parses the fleet and advisor configs" do
    mock_product(%{venue_id: :venue_a, symbol: :btc_usd})
    mock_product(%{venue_id: :venue_b, symbol: :eth_usd})

    fleet_app_config = %{
      fleet_a: %{
        start_on_boot: true,
        restart: :permanent,
        shutdown: 1000,
        advisor: AdvisorA,
        factory: Tai.Advisors.Factories.OnePerProduct,
        quotes: "*",
        config: %{min_profit: 0.1},
      }
    }

    assert {:ok, {loaded_fleets, loaded_advisors}} = Tai.Fleets.load(fleet_app_config)
    assert loaded_fleets == 1
    assert loaded_advisors == 2

    assert {:ok, fleet_config} = Tai.Fleets.FleetConfigStore.find(:fleet_a)
    assert fleet_config.id == :fleet_a
    assert fleet_config.advisor == AdvisorA
    assert fleet_config.factory == Tai.Advisors.Factories.OnePerProduct
    assert fleet_config.start_on_boot == true
    assert fleet_config.restart == :permanent
    assert fleet_config.shutdown == 1000
    assert fleet_config.quotes == "*"
    assert fleet_config.config == %{min_profit: 0.1}

    assert {:ok, _} = Tai.Fleets.AdvisorConfigStore.find({:venue_a_btc_usd, :fleet_a})
    assert {:ok, _} = Tai.Fleets.AdvisorConfigStore.find({:venue_b_eth_usd, :fleet_a})
  end

  test "start_on_boot is false when not present" do
    mock_product(%{venue_id: :venue_a, symbol: :btc_usd})

    fleet_app_config = %{
      fleet_a: %{
        advisor: AdvisorA,
        factory: Tai.Advisors.Factories.OnePerProduct,
        quotes: "*",
      }
    }

    assert {:ok, _} = Tai.Fleets.load(fleet_app_config)

    assert {:ok, fleet_config} = Tai.Fleets.FleetConfigStore.find(:fleet_a)
    assert fleet_config.start_on_boot == false
  end

  test "restart is temporary when not present" do
    mock_product(%{venue_id: :venue_a, symbol: :btc_usd})

    fleet_app_config = %{
      fleet_a: %{
        advisor: AdvisorA,
        factory: Tai.Advisors.Factories.OnePerProduct,
        quotes: "*",
      }
    }

    assert {:ok, _} = Tai.Fleets.load(fleet_app_config)

    assert {:ok, fleet_config} = Tai.Fleets.FleetConfigStore.find(:fleet_a)
    assert fleet_config.restart == :temporary
  end

  test "shutdown is 5000 when not present" do
    mock_product(%{venue_id: :venue_a, symbol: :btc_usd})

    fleet_app_config = %{
      fleet_a: %{
        advisor: AdvisorA,
        factory: Tai.Advisors.Factories.OnePerProduct,
        quotes: "*",
      }
    }

    assert {:ok, _} = Tai.Fleets.load(fleet_app_config)

    assert {:ok, fleet_config} = Tai.Fleets.FleetConfigStore.find(:fleet_a)
    assert fleet_config.shutdown == 5000
  end

  test "config is an empty map when not present" do
    mock_product(%{venue_id: :venue_a, symbol: :btc_usd})

    fleet_app_config = %{
      fleet_a: %{
        advisor: AdvisorA,
        factory: Tai.Advisors.Factories.OnePerProduct,
        quotes: "*",
      }
    }

    assert {:ok, _} = Tai.Fleets.load(fleet_app_config)

    assert {:ok, fleet_config} = Tai.Fleets.FleetConfigStore.find(:fleet_a)
    assert fleet_config.config == %{}
  end

  test "config can be parsed into a struct" do
    mock_product(%{venue_id: :venue_a, symbol: :btc_usd})

    fleet_app_config = %{
      fleet_a: %{
        advisor: AdvisorA,
        factory: Tai.Advisors.Factories.OnePerProduct,
        quotes: "*",
        config: {TestConfig, %{
          my_product: :custom_config
        }}
      }
    }

    assert {:ok, _} = Tai.Fleets.load(fleet_app_config)

    assert {:ok, fleet_config} = Tai.Fleets.FleetConfigStore.find(:fleet_a)
    assert fleet_config.config == %TestConfig{my_product: :custom_config}
  end

  test "config can substitute rich types" do
    mock_product(%{venue_id: :venue_a, symbol: :btc_usd})

    fleet_app_config = %{
      fleet_a: %{
        advisor: AdvisorA,
        factory: Tai.Advisors.Factories.OnePerProduct,
        quotes: "*",
        config: {TestConfig, %{
          my_product: {{:venue_a, :btc_usd}, :product}
        }}
      }
    }

    assert {:ok, _} = Tai.Fleets.load(fleet_app_config)

    assert {:ok, fleet_config} = Tai.Fleets.FleetConfigStore.find(:fleet_a)
    assert %TestConfig{my_product: my_product} = fleet_config.config
    assert %Tai.Venues.Product{venue_id: :venue_a, symbol: :btc_usd} = my_product
  end
end
