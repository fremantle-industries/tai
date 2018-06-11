defmodule Examples.Advisors.FillOrKillOrders.SupervisorTest do
  use ExUnit.Case
  doctest Examples.Advisors.FillOrKillOrders.Supervisor

  test "starts an advisor for each order book feed" do
    assert [
             {:fill_or_kill_orders_test_feed_a_btcusd, pid_a, :worker,
              [Examples.Advisors.FillOrKillOrders.Advisor]},
             {:fill_or_kill_orders_test_feed_a_ltcusd, pid_b, :worker,
              [Examples.Advisors.FillOrKillOrders.Advisor]},
             {:fill_or_kill_orders_test_feed_b_ethusd, pid_c, :worker,
              [Examples.Advisors.FillOrKillOrders.Advisor]}
           ] = Supervisor.which_children(Examples.Advisors.FillOrKillOrders.Supervisor)

    assert %Tai.Advisor{
             advisor_id: :fill_or_kill_orders_test_feed_a_btcusd,
             accounts: [],
             order_books: %{
               test_feed_a: [:btcusd]
             },
             store: %{}
           } = :sys.get_state(pid_a)

    assert %Tai.Advisor{
             advisor_id: :fill_or_kill_orders_test_feed_a_ltcusd,
             accounts: [],
             order_books: %{
               test_feed_a: [:ltcusd]
             },
             store: %{}
           } = :sys.get_state(pid_b)

    assert %Tai.Advisor{
             advisor_id: :fill_or_kill_orders_test_feed_b_ethusd,
             accounts: [],
             order_books: %{
               test_feed_b: [:ethusd]
             },
             store: %{}
           } = :sys.get_state(pid_c)
  end
end
