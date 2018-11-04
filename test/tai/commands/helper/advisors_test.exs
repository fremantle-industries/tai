defmodule Tai.Commands.Helper.AdvisorsTest do
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

  test "shows all advisors and their run status" do
    mock_product(%{exchange_id: :exchange_a, symbol: :btc_usdt})
    mock_product(%{exchange_id: :exchange_b, symbol: :eth_usdt})

    assert capture_io(&Tai.Commands.Helper.advisors/0) == """
           +------------+---------------------+--------+-----------+-----+
           |   Group ID |          Advisor ID | Config |    Status | PID |
           +------------+---------------------+--------+-----------+-----+
           | log_spread | exchange_a_btc_usdt |    %{} | unstarted |   - |
           | log_spread | exchange_b_eth_usdt |    %{} | unstarted |   - |
           +------------+---------------------+--------+-----------+-----+\n
           """
  end

  test "shows an empty table when there are no advisors" do
    assert capture_io(&Tai.Commands.Helper.advisors/0) == """
           +----------+------------+--------+--------+-----+
           | Group ID | Advisor ID | Config | Status | PID |
           +----------+------------+--------+--------+-----+
           |        - |          - |      - |      - |   - |
           +----------+------------+--------+--------+-----+\n
           """
  end

  test "starts and stops all advisors in all groups" do
    mock_product(%{
      exchange_id: :test_exchange_a,
      symbol: :btc_usdt
    })

    mock_product(%{
      exchange_id: :test_exchange_b,
      symbol: :eth_usdt
    })

    assert capture_io(&Tai.Commands.Helper.start_advisors/0) == """
           Started advisors: 3 new, 0 already running
           """

    output = capture_io(&Tai.Commands.Helper.advisors/0)
    assert output =~ ~r/\|\s+Group ID \|\s+Advisor ID \|\s+Config \|\s+Status \|\s+PID \|/

    assert output =~
             ~r/\|\s+fill_or_kill_orders \|\s+test_exchange_a_btc_usdt \|\s+%{} \|\s+running \|\s+#PID<.+> \|/

    assert output =~
             ~r/\|\s+log_spread \|\s+test_exchange_a_btc_usdt \|\s+%{} \|\s+running \|\s+#PID<.+> \|/

    assert output =~
             ~r/\|\s+log_spread \|\s+test_exchange_b_eth_usdt \|\s+%{} \|\s+running \|\s+#PID<.+> \|/

    assert capture_io(&Tai.Commands.Helper.stop_advisors/0) == """
           Stopped advisors: 3 new, 0 already stopped
           """

    assert capture_io(&Tai.Commands.Helper.advisors/0) == """
           +---------------------+--------------------------+--------+-----------+-----+
           |            Group ID |               Advisor ID | Config |    Status | PID |
           +---------------------+--------------------------+--------+-----------+-----+
           | fill_or_kill_orders | test_exchange_a_btc_usdt |    %{} | unstarted |   - |
           |          log_spread | test_exchange_a_btc_usdt |    %{} | unstarted |   - |
           |          log_spread | test_exchange_b_eth_usdt |    %{} | unstarted |   - |
           +---------------------+--------------------------+--------+-----------+-----+\n
           """
  end

  test "starts and stops all advisors in a single group" do
    mock_product(%{
      exchange_id: :test_exchange_a,
      symbol: :btc_usdt
    })

    mock_product(%{
      exchange_id: :test_exchange_b,
      symbol: :eth_usdt
    })

    assert capture_io(fn -> Tai.Commands.Helper.start_advisor_group(:log_spread) end) == """
           Started advisors: 2 new, 0 already running
           """

    output = capture_io(&Tai.Commands.Helper.advisors/0)
    assert output =~ ~r/\|\s+Group ID \|\s+Advisor ID \|\s+Config \|\s+Status \|\s+PID \|/
    refute output =~ ~r/\|\s+fill_or_kill_orders.+running \|\s+#PID<.+> \|/

    assert output =~
             ~r/\|\s+log_spread \|\s+test_exchange_a_btc_usdt \|\s+%{} \|\s+running \|\s+#PID<.+> \|/

    assert output =~
             ~r/\|\s+log_spread \|\s+test_exchange_b_eth_usdt \|\s+%{} \|\s+running \|\s+#PID<.+> \|/

    assert capture_io(fn -> Tai.Commands.Helper.stop_advisor_group(:log_spread) end) == """
           Stopped advisors: 2 new, 0 already stopped
           """

    assert capture_io(&Tai.Commands.Helper.advisors/0) == """
           +---------------------+--------------------------+--------+-----------+-----+
           |            Group ID |               Advisor ID | Config |    Status | PID |
           +---------------------+--------------------------+--------+-----------+-----+
           | fill_or_kill_orders | test_exchange_a_btc_usdt |    %{} | unstarted |   - |
           |          log_spread | test_exchange_a_btc_usdt |    %{} | unstarted |   - |
           |          log_spread | test_exchange_b_eth_usdt |    %{} | unstarted |   - |
           +---------------------+--------------------------+--------+-----------+-----+\n
           """
  end

  test "starts and stops a single advisor in a group" do
    mock_product(%{
      exchange_id: :test_exchange_a,
      symbol: :btc_usdt
    })

    mock_product(%{
      exchange_id: :test_exchange_b,
      symbol: :eth_usdt
    })

    assert capture_io(fn ->
             Tai.Commands.Helper.start_advisor(:log_spread, :test_exchange_a_btc_usdt)
           end) == """
           Started advisors: 1 new, 0 already running
           """

    output = capture_io(&Tai.Commands.Helper.advisors/0)
    assert output =~ ~r/\|\s+Group ID \|\s+Advisor ID \|\s+Config \|\s+Status \|\s+PID \|/

    assert output =~
             ~r/\|\s+log_spread \|\s+test_exchange_a_btc_usdt \|\s+%{} \|\s+running \|\s+#PID<.+> \|/

    refute output =~ ~r/\|\s+log_spread \|\s+test_exchange_b_eth_usdt.+running \|\s+#PID<.+> \|/
    refute output =~ ~r/\|\s+fill_or_kill_orders.+running \|\s+#PID<.+> \|/

    assert capture_io(fn ->
             Tai.Commands.Helper.stop_advisor(:log_spread, :test_exchange_a_btc_usdt)
           end) == """
           Stopped advisors: 1 new, 0 already stopped
           """

    assert capture_io(&Tai.Commands.Helper.advisors/0) == """
           +---------------------+--------------------------+--------+-----------+-----+
           |            Group ID |               Advisor ID | Config |    Status | PID |
           +---------------------+--------------------------+--------+-----------+-----+
           | fill_or_kill_orders | test_exchange_a_btc_usdt |    %{} | unstarted |   - |
           |          log_spread | test_exchange_a_btc_usdt |    %{} | unstarted |   - |
           |          log_spread | test_exchange_b_eth_usdt |    %{} | unstarted |   - |
           +---------------------+--------------------------+--------+-----------+-----+\n
           """
  end
end
