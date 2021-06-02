defmodule Tai.IEx.Commands.AdvisorsTest do
  use Tai.TestSupport.DataCase, async: false
  import ExUnit.CaptureIO
  import Support.Advisors, only: [insert_spec: 1]

  test "shows all advisors in all groups ordered group id, advisor id by default" do
    insert_spec(%{group_id: :log_spread, advisor_id: :a})
    insert_spec(%{group_id: :log_spread, advisor_id: :b})
    insert_spec(%{group_id: :trade_spread, advisor_id: :a})

    assert capture_io(&Tai.IEx.advisors/0) == """
           +--------------+------------+-----------+-----+
           |     Group ID | Advisor ID |    Status | PID |
           +--------------+------------+-----------+-----+
           |   log_spread |          a | unstarted |   - |
           |   log_spread |          b | unstarted |   - |
           | trade_spread |          a | unstarted |   - |
           +--------------+------------+-----------+-----+\n
           """
  end

  test "shows an empty table when there are no advisors" do
    assert capture_io(&Tai.IEx.advisors/0) == """
           +----------+------------+--------+-----+
           | Group ID | Advisor ID | Status | PID |
           +----------+------------+--------+-----+
           |        - |          - |      - |   - |
           +----------+------------+--------+-----+\n
           """
  end

  test "can filter by struct attributes" do
    insert_spec(%{group_id: :log_spread, advisor_id: :a})
    insert_spec(%{group_id: :log_spread, advisor_id: :b})
    insert_spec(%{group_id: :trade_spread, advisor_id: :a})

    assert capture_io(fn -> Tai.IEx.advisors(where: [group_id: :log_spread]) end) == """
           +------------+------------+-----------+-----+
           |   Group ID | Advisor ID |    Status | PID |
           +------------+------------+-----------+-----+
           | log_spread |          a | unstarted |   - |
           | log_spread |          b | unstarted |   - |
           +------------+------------+-----------+-----+\n
           """
  end

  test "can order ascending by struct attributes" do
    insert_spec(%{group_id: :log_spread, advisor_id: :a})
    insert_spec(%{group_id: :log_spread, advisor_id: :b})
    insert_spec(%{group_id: :trade_spread, advisor_id: :a})

    assert capture_io(fn -> Tai.IEx.advisors(order: [:advisor_id, :group_id]) end) == """
           +--------------+------------+-----------+-----+
           |     Group ID | Advisor ID |    Status | PID |
           +--------------+------------+-----------+-----+
           |   log_spread |          a | unstarted |   - |
           | trade_spread |          a | unstarted |   - |
           |   log_spread |          b | unstarted |   - |
           +--------------+------------+-----------+-----+\n
           """
  end
end
