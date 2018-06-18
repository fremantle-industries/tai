defmodule Examples.Advisors.LogSpread.SupervisorTest do
  use ExUnit.Case
  doctest Examples.Advisors.LogSpread.Supervisor

  test "starts a single advisor for all given order book feeds" do
    assert [
             {:log_spread_advisor, pid, :worker, [Examples.Advisors.LogSpread.Advisor]}
           ] = Supervisor.which_children(Examples.Advisors.LogSpread.Supervisor)

    assert %Tai.Advisor{
             advisor_id: :log_spread_advisor,
             accounts: [],
             order_books: %{
               test_feed_a: [:btc_usd, :ltc_usd],
               test_feed_b: [:eth_usd, :ltc_usd]
             },
             store: %{}
           } = :sys.get_state(pid)
  end
end
