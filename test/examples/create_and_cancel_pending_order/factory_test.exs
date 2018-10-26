defmodule Examples.Advisors.CreateAndCancelPendingOrder.FactoryTest do
  use ExUnit.Case, async: true
  doctest Examples.Advisors.CreateAndCancelPendingOrder.Factory

  test ".advisor_specs returns a supervisable child spec for each product on the given exchanges" do
    group = %Tai.AdvisorGroup{
      id: :group_a,
      products: "*"
    }

    assert Examples.Advisors.CreateAndCancelPendingOrder.Factory.advisor_specs(group, %{}) == []

    products_by_exchange = %{
      exchange_a: [:btc_usdt, :eth_usdt],
      exchange_b: [:btc_usdt, :ltc_usdt]
    }

    assert Examples.Advisors.CreateAndCancelPendingOrder.Factory.advisor_specs(
             group,
             products_by_exchange
           ) == [
             {
               Examples.Advisors.CreateAndCancelPendingOrder.Advisor,
               [
                 group_id: :group_a,
                 advisor_id: :exchange_a_btc_usdt,
                 order_books: %{exchange_a: [:btc_usdt]},
                 store: %{}
               ]
             },
             {
               Examples.Advisors.CreateAndCancelPendingOrder.Advisor,
               [
                 group_id: :group_a,
                 advisor_id: :exchange_a_eth_usdt,
                 order_books: %{exchange_a: [:eth_usdt]},
                 store: %{}
               ]
             },
             {
               Examples.Advisors.CreateAndCancelPendingOrder.Advisor,
               [
                 group_id: :group_a,
                 advisor_id: :exchange_b_btc_usdt,
                 order_books: %{exchange_b: [:btc_usdt]},
                 store: %{}
               ]
             },
             {
               Examples.Advisors.CreateAndCancelPendingOrder.Advisor,
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
