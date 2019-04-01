defmodule Tai.AdvisorGroups.ParseConfigTest do
  use ExUnit.Case, async: true

  test "returns an ok tuple with a list of advisor groups" do
    config =
      Tai.Config.parse(
        advisor_groups: %{
          group_a: [
            advisor: AdvisorA,
            factory: TestFactoryA,
            products: "*",
            config: %{min_profit: 0.1}
          ],
          group_b: [
            advisor: AdvisorB,
            factory: TestFactoryB,
            products: "btc_usdt"
          ]
        }
      )

    assert {:ok, groups} = Tai.AdvisorGroups.parse_config(config)
    assert Enum.count(groups) == 2

    assert groups |> List.first() == %Tai.AdvisorGroup{
             id: :group_a,
             advisor: AdvisorA,
             factory: TestFactoryA,
             products: "*",
             config: %{min_profit: 0.1}
           }

    assert groups |> List.last() == %Tai.AdvisorGroup{
             id: :group_b,
             advisor: AdvisorB,
             factory: TestFactoryB,
             products: "btc_usdt",
             config: %{}
           }
  end

  test "assigns an empty config map when not present" do
    config =
      Tai.Config.parse(
        advisor_groups: %{
          group_a: [
            advisor: AdvisorA,
            factory: TestFactoryA,
            products: "btc_usdt"
          ]
        }
      )

    assert {:ok, [group | _]} = Tai.AdvisorGroups.parse_config(config)
    assert group.config == %{}
  end

  test "returns an error tuple when advisor is not present" do
    config =
      Tai.Config.parse(
        advisor_groups: %{
          group_a: [
            factory: TestFactoryA,
            products: "*"
          ]
        }
      )

    assert {:error, errors} = Tai.AdvisorGroups.parse_config(config)
    assert errors.group_a == [{:advisor, "must be present"}]
  end

  test "returns an error tuple when factory is not present" do
    config =
      Tai.Config.parse(
        advisor_groups: %{
          group_a: [
            advisor: TestAdvisorA,
            products: "*"
          ]
        }
      )

    assert {:error, errors} = Tai.AdvisorGroups.parse_config(config)
    assert errors.group_a == [{:factory, "must be present"}]
  end

  test "returns an error tuple when products are not present" do
    config =
      Tai.Config.parse(
        advisor_groups: %{
          group_b: [
            advisor: TestAdvisorB,
            factory: TestFactoryB
          ]
        }
      )

    assert {:error, errors} = Tai.AdvisorGroups.parse_config(config)
    assert errors.group_b == [{:products, "must be present"}]
  end
end
