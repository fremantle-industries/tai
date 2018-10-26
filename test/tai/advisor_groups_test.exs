defmodule Tai.AdvisorGroupsTest do
  use ExUnit.Case, async: true
  doctest Tai.AdvisorGroups

  describe ".parse_config" do
    test "returns an ok tuple with a list of advisor groups" do
      config =
        Tai.Config.parse(
          advisor_groups: %{
            group_a: [
              factory: MyTestFactoryA,
              products: "*"
            ],
            group_b: [
              factory: MyTestFactoryB,
              products: "btc_usdt"
            ]
          }
        )

      assert Tai.AdvisorGroups.parse_config(config) == {
               :ok,
               [
                 %Tai.AdvisorGroup{
                   id: :group_a,
                   factory: MyTestFactoryA,
                   products: "*"
                 },
                 %Tai.AdvisorGroup{
                   id: :group_b,
                   factory: MyTestFactoryB,
                   products: "btc_usdt"
                 }
               ]
             }
    end

    test "returns an error tuple when factory is not present" do
      config =
        Tai.Config.parse(
          advisor_groups: %{
            group_a: [
              products: "*"
            ],
            group_b: [
              factory: MyTestFactoryB,
              products: "btc_usdt"
            ]
          }
        )

      assert Tai.AdvisorGroups.parse_config(config) ==
               {:error, %{group_a: [:factory_not_present]}}
    end

    test "returns an error tuple when products are not present" do
      config =
        Tai.Config.parse(
          advisor_groups: %{
            group_a: [
              factory: MyTestFactoryA,
              products: "*"
            ],
            group_b: [
              factory: MyTestFactoryB
            ]
          }
        )

      assert Tai.AdvisorGroups.parse_config(config) ==
               {:error, %{group_b: [:products_not_present]}}
    end
  end
end
