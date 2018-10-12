defmodule Tai.AdvisorGroupTest do
  use ExUnit.Case, async: true
  doctest Tai.AdvisorGroup

  describe ".parse_configs" do
    test "returns an ok tuple with a list of advisor groups" do
      configs = %{
        group_a: [
          factory: MyTestFactoryA,
          products: "*"
        ],
        group_b: [
          factory: MyTestFactoryB,
          products: "btc_usdt"
        ]
      }

      assert Tai.AdvisorGroup.parse_configs(configs) == {
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
      configs = %{
        group_a: [
          products: "*"
        ],
        group_b: [
          factory: MyTestFactoryB,
          products: "btc_usdt"
        ]
      }

      assert Tai.AdvisorGroup.parse_configs(configs) ==
               {:error, %{group_a: [:factory_not_present]}}
    end

    test "returns an error tuple when products are not present" do
      configs = %{
        group_a: [
          factory: MyTestFactoryA,
          products: "*"
        ],
        group_b: [
          factory: MyTestFactoryB
        ]
      }

      assert Tai.AdvisorGroup.parse_configs(configs) ==
               {:error, %{group_b: [:products_not_present]}}
    end
  end
end
