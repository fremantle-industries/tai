defmodule Tai.IEx.Commands.AdvisorsTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  import Support.Advisors, only: [insert_spec: 2]

  @test_store_id __MODULE__

  setup do
    start_supervised!({Tai.Advisors.SpecStore, id: @test_store_id})
    start_supervised!(Tai.Commander)
    :ok
  end

  test "shows all advisors in all groups ordered group id, advisor id by default" do
    insert_spec(%{group_id: :log_spread, advisor_id: :a}, @test_store_id)
    insert_spec(%{group_id: :log_spread, advisor_id: :b}, @test_store_id)
    insert_spec(%{group_id: :trade_spread, advisor_id: :a}, @test_store_id)

    assert capture_io(fn -> Tai.IEx.advisors(store_id: @test_store_id) end) == """
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
    assert capture_io(fn -> Tai.IEx.advisors(store_id: @test_store_id) end) == """
           +----------+------------+--------+-----+
           | Group ID | Advisor ID | Status | PID |
           +----------+------------+--------+-----+
           |        - |          - |      - |   - |
           +----------+------------+--------+-----+\n
           """
  end

  test "can filter by struct attributes" do
    insert_spec(%{group_id: :log_spread, advisor_id: :a}, @test_store_id)
    insert_spec(%{group_id: :log_spread, advisor_id: :b}, @test_store_id)
    insert_spec(%{group_id: :trade_spread, advisor_id: :a}, @test_store_id)

    assert capture_io(fn ->
             Tai.IEx.advisors(
               where: [group_id: :log_spread],
               store_id: @test_store_id
             )
           end) == """
           +------------+------------+-----------+-----+
           |   Group ID | Advisor ID |    Status | PID |
           +------------+------------+-----------+-----+
           | log_spread |          a | unstarted |   - |
           | log_spread |          b | unstarted |   - |
           +------------+------------+-----------+-----+\n
           """
  end

  test "can order ascending by struct attributes" do
    insert_spec(%{group_id: :log_spread, advisor_id: :a}, @test_store_id)
    insert_spec(%{group_id: :log_spread, advisor_id: :b}, @test_store_id)
    insert_spec(%{group_id: :trade_spread, advisor_id: :a}, @test_store_id)

    assert capture_io(fn ->
             Tai.IEx.advisors(
               order: [:advisor_id, :group_id],
               store_id: @test_store_id
             )
           end) == """
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
