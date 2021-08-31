defmodule Tai.IEx.Commands.AdvisorsTest do
  use Tai.TestSupport.DataCase, async: false
  import ExUnit.CaptureIO

  test "shows all advisors in all fleets ordered fleet id, advisor id by default" do
    mock_advisor_config(%{fleet_id: :log_spread, advisor_id: :a})
    mock_advisor_config(%{fleet_id: :log_spread, advisor_id: :b})
    mock_advisor_config(%{fleet_id: :trade_spread, advisor_id: :a})

    assert capture_io(&Tai.IEx.advisors/0) == """
           +--------------+------------+-----------+-----+--------+
           |     Fleet ID | Advisor ID |    Status | PID | Config |
           +--------------+------------+-----------+-----+--------+
           |   log_spread |          a | unstarted |   - |    %{} |
           |   log_spread |          b | unstarted |   - |    %{} |
           | trade_spread |          a | unstarted |   - |    %{} |
           +--------------+------------+-----------+-----+--------+\n
           """
  end

  test "shows an empty table when there are no advisors" do
    assert capture_io(&Tai.IEx.advisors/0) == """
           +----------+------------+--------+-----+--------+
           | Fleet ID | Advisor ID | Status | PID | Config |
           +----------+------------+--------+-----+--------+
           |        - |          - |      - |   - |      - |
           +----------+------------+--------+-----+--------+\n
           """
  end

  test "can filter by struct attributes" do
    mock_advisor_config(%{fleet_id: :log_spread, advisor_id: :a})
    mock_advisor_config(%{fleet_id: :log_spread, advisor_id: :b})
    mock_advisor_config(%{fleet_id: :trade_spread, advisor_id: :a})

    assert capture_io(fn -> Tai.IEx.advisors(where: [fleet_id: :log_spread]) end) == """
           +------------+------------+-----------+-----+--------+
           |   Fleet ID | Advisor ID |    Status | PID | Config |
           +------------+------------+-----------+-----+--------+
           | log_spread |          a | unstarted |   - |    %{} |
           | log_spread |          b | unstarted |   - |    %{} |
           +------------+------------+-----------+-----+--------+\n
           """
  end

  test "can order ascending by struct attributes" do
    mock_advisor_config(%{fleet_id: :log_spread, advisor_id: :a})
    mock_advisor_config(%{fleet_id: :log_spread, advisor_id: :b})
    mock_advisor_config(%{fleet_id: :trade_spread, advisor_id: :a})

    assert capture_io(fn -> Tai.IEx.advisors(order: [:advisor_id, :fleet_id]) end) == """
           +--------------+------------+-----------+-----+--------+
           |     Fleet ID | Advisor ID |    Status | PID | Config |
           +--------------+------------+-----------+-----+--------+
           |   log_spread |          a | unstarted |   - |    %{} |
           | trade_spread |          a | unstarted |   - |    %{} |
           |   log_spread |          b | unstarted |   - |    %{} |
           +--------------+------------+-----------+-----+--------+\n
           """
  end
end
