defmodule Examples.Advisors.LogSpread.SupervisorTest do
  use ExUnit.Case
  doctest Examples.Advisors.LogSpread.Supervisor

  test "starts a single advisor for all given order book feeds" do
    assert [
             {:log_spread_advisor, pid, :worker, [Examples.Advisors.LogSpread.Advisor]}
           ] = Supervisor.which_children(Examples.Advisors.LogSpread.Supervisor)

    assert %Tai.Advisor{
             advisor_id: :log_spread_advisor,
             exchanges: [],
             order_books: %{
               test_feed_a: [:btcusd, :ltcusd],
               test_feed_b: [:ethusd, :ltcusd]
             },
             store: %{}
           } = :sys.get_state(pid)
  end
end
