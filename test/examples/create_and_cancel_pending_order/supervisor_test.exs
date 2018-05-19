defmodule Examples.Advisors.CreateAndCancelPendingOrder.SupervisorTest do
  use ExUnit.Case
  doctest Examples.Advisors.CreateAndCancelPendingOrder.Supervisor

  test "starts an advisor for each order book feed" do
    assert [
             {:create_and_cancel_pending_order_test_feed_a_btcusd, pid_a, :worker,
              [Examples.Advisors.CreateAndCancelPendingOrder.Advisor]},
             {:create_and_cancel_pending_order_test_feed_a_ltcusd, pid_b, :worker,
              [Examples.Advisors.CreateAndCancelPendingOrder.Advisor]},
             {:create_and_cancel_pending_order_test_feed_b_ethusd, pid_c, :worker,
              [Examples.Advisors.CreateAndCancelPendingOrder.Advisor]}
           ] = Supervisor.which_children(Examples.Advisors.CreateAndCancelPendingOrder.Supervisor)

    assert %Tai.Advisor{
             advisor_id: :create_and_cancel_pending_order_test_feed_a_btcusd,
             accounts: [],
             order_books: %{
               test_feed_a: [:btcusd]
             },
             store: %{}
           } = :sys.get_state(pid_a)

    assert %Tai.Advisor{
             advisor_id: :create_and_cancel_pending_order_test_feed_a_ltcusd,
             accounts: [],
             order_books: %{
               test_feed_a: [:ltcusd]
             },
             store: %{}
           } = :sys.get_state(pid_b)

    assert %Tai.Advisor{
             advisor_id: :create_and_cancel_pending_order_test_feed_b_ethusd,
             accounts: [],
             order_books: %{
               test_feed_b: [:ethusd]
             },
             store: %{}
           } = :sys.get_state(pid_c)
  end
end
