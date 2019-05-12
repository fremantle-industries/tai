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

  test "shows all advisor groups and the status of their advisors" do
    mock_product(%{venue_id: :test_exchange_a, symbol: :btc_usd})
    mock_product(%{venue_id: :test_exchange_b, symbol: :eth_usd})

    assert capture_io(&Tai.Commands.Helper.advisor_groups/0) == """
           +---------------------------------+---------+-----------+-------+
           |                        Group ID | Running | Unstarted | Total |
           +---------------------------------+---------+-----------+-------+
           |                      log_spread |       0 |         2 |     2 |
           |             fill_or_kill_orders |       0 |         2 |     2 |
           | create_and_cancel_pending_order |       0 |         1 |     1 |
           +---------------------------------+---------+-----------+-------+\n
           """
  end

  test "shows an empty table when there are no advisor groups" do
    config = struct(Tai.Config, advisor_groups: %{})

    assert capture_io(fn -> Tai.Commands.Helper.advisor_groups(config) end) == """
           +----------+---------+-----------+-------+
           | Group ID | Running | Unstarted | Total |
           +----------+---------+-----------+-------+
           |        - |       - |         - |     - |
           +----------+---------+-----------+-------+\n
           """
  end
end
