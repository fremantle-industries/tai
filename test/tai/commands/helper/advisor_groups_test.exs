defmodule Tai.Commands.Helper.AdvisorGroupsTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  import Tai.TestSupport.Mock

  setup do
    on_exit(fn ->
      Tai.TestSupport.Helpers.restart_application()
    end)
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
           Started 2 advisors
           """

    output = capture_io(&Tai.Commands.Helper.advisors/0)
    assert output =~ ~r/\|\s+Group ID \|\s+Advisor ID \|\s+Status \|\s+PID \|/
    assert output =~ ~r/\| log_spread \| exchange_a_btc_usdt \| running \| #PID<.+> \|/
    assert output =~ ~r/\| log_spread \| exchange_b_eth_usdt \| running \| #PID<.+> \|/

    assert capture_io(&Tai.Commands.Helper.stop_advisor_groups/0) == """
           Stopped 2 advisors
           """

    assert capture_io(&Tai.Commands.Helper.advisors/0) == """
           +------------+---------------------+-----------+-----+
           |   Group ID |          Advisor ID |    Status | PID |
           +------------+---------------------+-----------+-----+
           | log_spread | exchange_a_btc_usdt | unstarted |   - |
           | log_spread | exchange_b_eth_usdt | unstarted |   - |
           +------------+---------------------+-----------+-----+\n
           """
  end
end
