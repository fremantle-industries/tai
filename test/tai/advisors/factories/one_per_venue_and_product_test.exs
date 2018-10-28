defmodule Tai.Advisors.Factories.OnePerVenueAndProductTest do
  use ExUnit.Case, async: true
  doctest Tai.Advisors.Factories.OnePerVenueAndProduct

  test "returns an advisor spec for each product on the given venues" do
    group = %Tai.AdvisorGroup{
      advisor: MyAdvisor,
      factory: Tai.Advisors.Factories.OnePerVenueAndProduct,
      id: :group_a,
      products: "*",
      store: %{}
    }

    assert Tai.Advisors.Factories.OnePerVenueAndProduct.advisor_specs(group, %{}) == []

    products_by_exchange = %{
      exchange_a: [:btc_usdt, :eth_usdt],
      exchange_b: [:btc_usdt, :ltc_usdt]
    }

    assert Tai.Advisors.Factories.OnePerVenueAndProduct.advisor_specs(
             group,
             products_by_exchange
           ) == [
             {
               MyAdvisor,
               [
                 group_id: :group_a,
                 advisor_id: :exchange_a_btc_usdt,
                 order_books: %{exchange_a: [:btc_usdt]},
                 store: %{}
               ]
             },
             {
               MyAdvisor,
               [
                 group_id: :group_a,
                 advisor_id: :exchange_a_eth_usdt,
                 order_books: %{exchange_a: [:eth_usdt]},
                 store: %{}
               ]
             },
             {
               MyAdvisor,
               [
                 group_id: :group_a,
                 advisor_id: :exchange_b_btc_usdt,
                 order_books: %{exchange_b: [:btc_usdt]},
                 store: %{}
               ]
             },
             {
               MyAdvisor,
               [
                 group_id: :group_a,
                 advisor_id: :exchange_b_ltc_usdt,
                 order_books: %{exchange_b: [:ltc_usdt]},
                 store: %{}
               ]
             }
           ]
  end
end
