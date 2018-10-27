defmodule Tai.AdvisorGroupsTest do
  use ExUnit.Case, async: true
  doctest Tai.AdvisorGroups

  defmodule TestFactoryA do
    def advisor_specs(group, filtered_product_symbols_by_exchange) do
      [
        {
          group.factory,
          [
            group_id: group.id,
            advisor_id: :advisor_a,
            order_books: %{exchange_a: filtered_product_symbols_by_exchange.exchange_a},
            store: %{}
          ]
        },
        {
          group.factory,
          [
            group_id: group.id,
            advisor_id: :advisor_b,
            order_books: %{exchange_a: filtered_product_symbols_by_exchange.exchange_a},
            store: %{}
          ]
        }
      ]
    end
  end

  describe ".parse_config" do
    test "returns an ok tuple with a list of advisor groups" do
      config =
        Tai.Config.parse(
          advisor_groups: %{
            group_a: [
              factory: TestFactoryA,
              products: "*",
              store: %{min_profit: 0.1}
            ],
            group_b: [
              factory: TestFactoryB,
              products: "btc_usdt"
            ]
          }
        )

      assert Tai.AdvisorGroups.parse_config(config) == {
               :ok,
               [
                 %Tai.AdvisorGroup{
                   id: :group_a,
                   factory: TestFactoryA,
                   products: "*",
                   store: %{min_profit: 0.1}
                 },
                 %Tai.AdvisorGroup{
                   id: :group_b,
                   factory: TestFactoryB,
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
              factory: TestFactoryB,
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
              factory: TestFactoryA,
              products: "*"
            ],
            group_b: [
              factory: TestFactoryB
            ]
          }
        )

      assert Tai.AdvisorGroups.parse_config(config) ==
               {:error, %{group_b: [:products_not_present]}}
    end
  end

  describe ".build_specs" do
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
              factory: TestFactoryA,
              products: "exchange_a exchange_b.ltc_usd"
            ]
          }
        )

      assert Tai.AdvisorGroups.build_specs(config_with_groups, product_symbols_by_exchange) == {
               :ok,
               [
                 {
                   TestFactoryA,
                   [
                     group_id: :group_a,
                     advisor_id: :advisor_a,
                     order_books: %{exchange_a: [:btc_usd, :eth_usd]},
                     store: %{}
                   ]
                 },
                 {
                   TestFactoryA,
                   [
                     group_id: :group_a,
                     advisor_id: :advisor_b,
                     order_books: %{exchange_a: [:btc_usd, :eth_usd]},
                     store: %{}
                   ]
                 }
               ]
             }
    end

    test "surfaces the errors from .parse_config" do
      config = Tai.Config.parse(advisor_groups: %{group_a: [factory: TestFactoryA]})

      assert Tai.AdvisorGroups.build_specs(config, %{}) ==
               {:error, %{group_a: [:products_not_present]}}
    end
  end

  describe ".build_specs_for_group" do
    test "returns advisor specs with filtered products from the factory of the given group" do
      config_without_groups = Tai.Config.parse(advisor_groups: %{})

      product_symbols_by_exchange = %{
        exchange_a: [:btc_usd, :eth_usd],
        exchange_b: [:btc_usd, :ltc_usd]
      }

      assert Tai.AdvisorGroups.build_specs_for_group(
               config_without_groups,
               :group_a,
               product_symbols_by_exchange
             ) == {:ok, []}

      config_with_groups =
        Tai.Config.parse(
          advisor_groups: %{
            group_a: [
              factory: TestFactoryA,
              products: "exchange_a exchange_b.ltc_usd"
            ],
            group_b: [
              factory: TestFactoryA,
              products: "*"
            ]
          }
        )

      assert Tai.AdvisorGroups.build_specs_for_group(
               config_with_groups,
               :group_a,
               product_symbols_by_exchange
             ) == {
               :ok,
               [
                 {
                   TestFactoryA,
                   [
                     group_id: :group_a,
                     advisor_id: :advisor_a,
                     order_books: %{exchange_a: [:btc_usd, :eth_usd]},
                     store: %{}
                   ]
                 },
                 {
                   TestFactoryA,
                   [
                     group_id: :group_a,
                     advisor_id: :advisor_b,
                     order_books: %{exchange_a: [:btc_usd, :eth_usd]},
                     store: %{}
                   ]
                 }
               ]
             }
    end

    test "surfaces the errors from .parse_config" do
      config = Tai.Config.parse(advisor_groups: %{group_a: [factory: TestFactoryA]})

      assert Tai.AdvisorGroups.build_specs_for_group(config, :group_a, %{}) ==
               {:error, %{group_a: [:products_not_present]}}
    end
  end

  describe ".build_specs_for_advisor" do
    test "returns advisor specs with filtered products from the factory of the given advisor & group" do
      config_without_groups = Tai.Config.parse(advisor_groups: %{})

      product_symbols_by_exchange = %{
        exchange_a: [:btc_usd, :eth_usd],
        exchange_b: [:btc_usd, :ltc_usd]
      }

      assert Tai.AdvisorGroups.build_specs_for_advisor(
               config_without_groups,
               :group_a,
               :advisor_a,
               product_symbols_by_exchange
             ) == {:ok, []}

      config_with_groups =
        Tai.Config.parse(
          advisor_groups: %{
            group_a: [
              factory: TestFactoryA,
              products: "exchange_a exchange_b.ltc_usd"
            ],
            group_b: [
              factory: TestFactoryA,
              products: "*"
            ]
          }
        )

      assert Tai.AdvisorGroups.build_specs_for_advisor(
               config_with_groups,
               :group_a,
               :advisor_a,
               product_symbols_by_exchange
             ) == {
               :ok,
               [
                 {
                   TestFactoryA,
                   [
                     group_id: :group_a,
                     advisor_id: :advisor_a,
                     order_books: %{exchange_a: [:btc_usd, :eth_usd]},
                     store: %{}
                   ]
                 }
               ]
             }
    end

    test "surfaces the errors from .parse_config" do
      config = Tai.Config.parse(advisor_groups: %{group_a: [factory: TestFactoryA]})

      assert Tai.AdvisorGroups.build_specs_for_advisor(config, :group_a, :advisor_a, %{}) ==
               {:error, %{group_a: [:products_not_present]}}
    end
  end
end
