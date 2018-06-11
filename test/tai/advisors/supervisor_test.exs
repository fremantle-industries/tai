defmodule Tai.Advisors.SupervisorTest do
  use ExUnit.Case
  doctest Tai.Advisors.Supervisor

  test "starts each configured advisor supervisor" do
    assert [
             {:log_spread_advisor, _, :supervisor, [Examples.Advisors.LogSpread.Supervisor]},
             {:fill_or_kill_orders, _, :supervisor,
              [Examples.Advisors.FillOrKillOrders.Supervisor]},
             {:create_and_cancel_pending_order, _, :supervisor,
              [Examples.Advisors.CreateAndCancelPendingOrder.Supervisor]}
           ] = Supervisor.which_children(Tai.Advisors.Supervisor)
  end
end
