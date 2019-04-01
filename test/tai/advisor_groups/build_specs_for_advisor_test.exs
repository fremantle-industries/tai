defmodule Tai.AdvisorGroups.BuildSpecsForAdvisorTest do
  use ExUnit.Case, async: true

  defmodule TestFactoryA do
    def advisor_specs(group, products) do
      products
      |> Enum.map(fn p ->
        order_books = %{} |> Map.put(p.venue_id, [p.symbol])

        {
          TestAdvisor,
          [
            group_id: group.id,
            advisor_id: :"advisor_#{p.venue_id}_#{p.symbol}",
            order_books: order_books,
            config: %{}
          ]
        }
      end)
    end
  end

  test "returns advisor specs with filtered products from the factory of the given advisor & group" do
    config_without_groups = Tai.Config.parse(advisor_groups: %{})

    product_1 = struct(Tai.Venues.Product, %{venue_id: :exchange_a, symbol: :btc_usd})
    product_2 = struct(Tai.Venues.Product, %{venue_id: :exchange_a, symbol: :eth_usd})
    product_3 = struct(Tai.Venues.Product, %{venue_id: :exchange_b, symbol: :btc_usd})
    product_4 = struct(Tai.Venues.Product, %{venue_id: :exchange_b, symbol: :ltc_usd})
    products = [product_1, product_2, product_3, product_4]

    assert Tai.AdvisorGroups.build_specs_for_advisor(
             config_without_groups,
             :group_a,
             :advisor_a,
             products
           ) == {:ok, []}

    config_with_groups =
      Tai.Config.parse(
        advisor_groups: %{
          group_a: [
            advisor: TestAdvisorA,
            factory: TestFactoryA,
            products: "exchange_a exchange_b.ltc_usd"
          ],
          group_b: [
            advisor: TestAdvisorB,
            factory: TestFactoryA,
            products: "*"
          ]
        }
      )

    assert Tai.AdvisorGroups.build_specs_for_advisor(
             config_with_groups,
             :group_a,
             :advisor_exchange_a_btc_usd,
             products
           ) == {
             :ok,
             [
               {
                 TestAdvisor,
                 [
                   group_id: :group_a,
                   advisor_id: :advisor_exchange_a_btc_usd,
                   order_books: %{exchange_a: [:btc_usd]},
                   config: %{}
                 ]
               }
             ]
           }
  end

  test "surfaces the errors from .parse_config" do
    config =
      Tai.Config.parse(advisor_groups: %{group_a: [advisor: TestAdvisorA, factory: TestFactoryA]})

    assert {:error, errors} =
             Tai.AdvisorGroups.build_specs_for_advisor(config, :group_a, :advisor_a, %{})

    assert errors.group_a == [{:products, "must be present"}]
  end
end
