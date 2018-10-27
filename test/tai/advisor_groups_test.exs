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
              products: "*",
              store: %{min_profit: 0.1}
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
                   products: "*",
                   store: %{min_profit: 0.1}
                 },
                 %Tai.AdvisorGroup{
                   id: :group_b,
                   factory: MyTestFactoryB,
                   products: "btc_usdt",
                   store: %{}
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

  describe ".build_specs" do
    defmodule MyTestFactory do
      def advisor_specs(group, filtered_product_symbols_by_exchange) do
        [
          {group.factory, filtered_product_symbols_by_exchange.exchange_a},
          {group.factory, filtered_product_symbols_by_exchange.exchange_b}
        ]
      end
    end

    test "returns advisor specs with filtered products from the groups factory" do
      config_without_groups = Tai.Config.parse(advisor_groups: %{})

      product_symbols_by_exchange = %{
        exchange_a: [:btc_usd, :eth_usd],
        exchange_b: [:btc_usd, :ltc_usd]
      }

      assert Tai.AdvisorGroups.build_specs(config_without_groups, product_symbols_by_exchange) ==
               {:ok, []}

      config_with_groups =
        Tai.Config.parse(
          advisor_groups: %{
            group_a: [
              factory: MyTestFactory,
              products: "exchange_a exchange_b.ltc_usd"
            ]
          }
        )

      assert Tai.AdvisorGroups.build_specs(config_with_groups, product_symbols_by_exchange) == {
               :ok,
               [
                 {MyTestFactory, [:btc_usd, :eth_usd]},
                 {MyTestFactory, [:ltc_usd]}
               ]
             }
    end

    test "surfaces the errors from .parse_config" do
      config =
        Tai.Config.parse(
          advisor_groups: %{
            group_a: [factory: MyTestFactoryB]
          }
        )

      assert Tai.AdvisorGroups.build_specs(config, %{}) ==
               {:error, %{group_a: [:products_not_present]}}
    end
  end
end
