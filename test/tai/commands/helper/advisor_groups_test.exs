defmodule Tai.Commands.Helper.AdvisorGroupsTest do
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

  test "starts and stops all advisors in all groups" do
    mock_product(%{
      exchange_id: :exchange_a,
      symbol: :btc_usdt
    })

    mock_product(%{
      exchange_id: :exchange_b,
      symbol: :eth_usdt
    })

    assert capture_io(&Tai.Commands.Helper.start_advisor_groups/0) == """
           Started advisors: 2 new, 0 already running
           """

    output = capture_io(&Tai.Commands.Helper.advisors/0)
    assert output =~ ~r/\|\s+Group ID \|\s+Advisor ID \|\s+Store \|\s+Status \|\s+PID \|/

    assert output =~
             ~r/\|\s+log_spread \|\s+exchange_a_btc_usdt \|\s+%{} \|\s+running \|\s+#PID<.+> \|/

    assert output =~
             ~r/\|\s+log_spread \|\s+exchange_b_eth_usdt \|\s+%{} \|\s+running \|\s+#PID<.+> \|/

    assert capture_io(&Tai.Commands.Helper.stop_advisor_groups/0) == """
           Stopped advisors: 2 new, 0 already stopped
           """

    assert capture_io(&Tai.Commands.Helper.advisors/0) == """
           +------------+---------------------+-------+-----------+-----+
           |   Group ID |          Advisor ID | Store |    Status | PID |
           +------------+---------------------+-------+-----------+-----+
           | log_spread | exchange_a_btc_usdt |   %{} | unstarted |   - |
           | log_spread | exchange_b_eth_usdt |   %{} | unstarted |   - |
           +------------+---------------------+-------+-----------+-----+\n
           """
  end
end
