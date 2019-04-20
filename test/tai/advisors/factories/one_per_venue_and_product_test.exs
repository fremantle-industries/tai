defmodule Tai.Advisors.Factories.OnePerVenueAndProductTest do
  use ExUnit.Case, async: true
  doctest Tai.Advisors.Factories.OnePerVenueAndProduct

  test "returns an advisor spec for each product on the given venues" do
    group = %Tai.AdvisorGroup{
      advisor: MyAdvisor,
      factory: Tai.Advisors.Factories.OnePerVenueAndProduct,
      id: :group_a,
      products: "*",
      config: %{hello: :world},
      trades: []
    }

    assert Tai.Advisors.Factories.OnePerVenueAndProduct.advisor_specs(group, []) == []

    product_1 = struct(Tai.Venues.Product, %{venue_id: :venue_a, symbol: :btc_usdt})
    product_2 = struct(Tai.Venues.Product, %{venue_id: :venue_b, symbol: :ltc_usdt})
    products = [product_1, product_2]

    assert [advisor_1, advisor_2] =
             Tai.Advisors.Factories.OnePerVenueAndProduct.advisor_specs(group, products)

    assert {
             MyAdvisor,
             [
               group_id: :group_a,
               advisor_id: :venue_a_btc_usdt,
               products: [^product_1],
               config: %{hello: :world}
             ]
           } = advisor_1

    assert {
             MyAdvisor,
             [
               group_id: :group_a,
               advisor_id: :venue_b_ltc_usdt,
               products: [^product_2],
               config: %{hello: :world}
             ]
           } = advisor_2
  end
end
