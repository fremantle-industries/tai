defmodule Tai.Commands.Helper.AdvisorTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  import Tai.TestSupport.Mock

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test "shows detailed information about the advisor" do
    mock_product(%{venue_id: :test_exchange_a, symbol: :btc_usd})
    mock_product(%{venue_id: :test_exchange_b, symbol: :eth_usd})

    assert capture_io(fn ->
             Tai.Commands.Helper.advisor(:log_spread, :test_exchange_a_btc_usd)
           end) ==
             """
             Group ID: log_spread
             Advisor ID: test_exchange_a_btc_usd
             Status: unstarted
             PID: -
             Config: %{}
             """
  end

  test "shows empty fields when there is no advisor in the group" do
    config = struct(Tai.Config, advisor_groups: %{})

    assert capture_io(fn ->
             Tai.Commands.Helper.advisor(:log_spread, :test_exchange_a_btc_usd, config)
           end) ==
             """
             Group ID: -
             Advisor ID: -
             Status: -
             PID: -
             Config: -
             """
  end

  test "can start and stop a single advisor in a group" do
    mock_product(%{venue_id: :test_exchange_a, symbol: :btc_usd})
    mock_product(%{venue_id: :test_exchange_b, symbol: :eth_usd})

    assert capture_io(fn ->
             Tai.Commands.Helper.start_advisor(:log_spread, :test_exchange_a_btc_usd)
           end) == """
           Started advisors: 1 new, 0 already running
           """

    output = capture_io(&Tai.Commands.Helper.advisors/0)
    assert output =~ ~r/\|\s+Group ID \|\s+Advisor ID \|\s+Status \|\s+PID \|/

    assert output =~
             ~r/\|\s+log_spread \|\s+test_exchange_a_btc_usd \|\s+running \|\s+#PID<.+> \|/

    refute output =~ ~r/\|\s+log_spread \|\s+test_exchange_b_eth_usdt.+running \|\s+#PID<.+> \|/
    refute output =~ ~r/\|\s+fill_or_kill_orders.+running \|\s+#PID<.+> \|/

    assert capture_io(fn ->
             Tai.Commands.Helper.stop_advisor(:log_spread, :test_exchange_a_btc_usd)
           end) == """
           Stopped advisors: 1 new, 0 already stopped
           """

    assert capture_io(&Tai.Commands.Helper.advisors/0) == """
           +---------------------------------+-------------------------+-----------+-----+
           |                        Group ID |              Advisor ID |    Status | PID |
           +---------------------------------+-------------------------+-----------+-----+
           | create_and_cancel_pending_order | test_exchange_a_btc_usd | unstarted |   - |
           |             fill_or_kill_orders | test_exchange_a_btc_usd | unstarted |   - |
           |             fill_or_kill_orders | test_exchange_b_eth_usd | unstarted |   - |
           |                      log_spread | test_exchange_a_btc_usd | unstarted |   - |
           |                      log_spread | test_exchange_b_eth_usd | unstarted |   - |
           +---------------------------------+-------------------------+-----------+-----+\n
           """
  end
end
