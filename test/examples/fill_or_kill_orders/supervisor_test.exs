defmodule Examples.Advisors.FillOrKillOrders.SupervisorTest do
  use ExUnit.Case
  doctest Examples.Advisors.FillOrKillOrders.Supervisor

  test "starts an advisor for each order book feed" do
    assert [
             {:fill_or_kill_orders_test_feed_a_btc_usd, pid_a, :worker,
              [Examples.Advisors.FillOrKillOrders.Advisor]},
             {:fill_or_kill_orders_test_feed_a_ltc_usd, pid_b, :worker,
              [Examples.Advisors.FillOrKillOrders.Advisor]},
             {:fill_or_kill_orders_test_feed_b_eth_usd, pid_c, :worker,
              [Examples.Advisors.FillOrKillOrders.Advisor]}
           ] = Supervisor.which_children(Examples.Advisors.FillOrKillOrders.Supervisor)

    assert %Tai.Advisor{
             advisor_id: :fill_or_kill_orders_test_feed_a_btc_usd,
             accounts: [],
             order_books: %{
               test_feed_a: [:btc_usd]
             },
             store: %{}
           } = :sys.get_state(pid_a)

    assert %Tai.Advisor{
             advisor_id: :fill_or_kill_orders_test_feed_a_ltc_usd,
             accounts: [],
             order_books: %{
               test_feed_a: [:ltc_usd]
             },
             store: %{}
           } = :sys.get_state(pid_b)

    assert %Tai.Advisor{
             advisor_id: :fill_or_kill_orders_test_feed_b_eth_usd,
             accounts: [],
             order_books: %{
               test_feed_b: [:eth_usd]
             },
             store: %{}
           } = :sys.get_state(pid_c)
  end
end
