defmodule Tai.AdvisorGroups.ParseConfigTest do
  use ExUnit.Case, async: true

  test "returns a list of parsed advisor groups" do
    config =
      Tai.Config.parse(
        advisor_groups: %{
          group_a: [
            advisor: AdvisorA,
            factory: TestFactoryA,
            products: "*",
            config: %{min_profit: 0.1},
            trades: [:a, :b]
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

    assert %Tai.AdvisorGroup{} = group_a = groups |> List.first()
    assert group_a.id == :group_a
    assert group_a.advisor == AdvisorA
    assert group_a.factory == TestFactoryA
    assert group_a.products == "*"
    assert group_a.config == %{min_profit: 0.1}
    assert group_a.trades == [:a, :b]

    assert %Tai.AdvisorGroup{} = group_b = groups |> List.last()
    assert group_b.id == :group_b
    assert group_b.advisor == AdvisorB
    assert group_b.factory == TestFactoryB
    assert group_b.products == "btc_usdt"
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

  test "assigns an empty trade list when not present" do
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
    assert group.trades == []
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
