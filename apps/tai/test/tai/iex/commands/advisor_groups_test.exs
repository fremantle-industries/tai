defmodule Tai.IEx.Commands.AdvisorGroupsTest do
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

    assert capture_io(fn -> Tai.IEx.advisor_groups(store_id: @test_store_id) end) == """
           +--------------+---------+----------+---------+-------+
           |        Group | Running | Starting | Stopped | Total |
           +--------------+---------+----------+---------+-------+
           |   log_spread |       0 |        0 |       2 |     2 |
           | trade_spread |       0 |        0 |       1 |     1 |
           +--------------+---------+----------+---------+-------+\n
           """
  end

  test "shows an empty table when there are no groups" do
    assert capture_io(fn -> Tai.IEx.advisor_groups(store_id: @test_store_id) end) == """
           +-------+---------+----------+---------+-------+
           | Group | Running | Starting | Stopped | Total |
           +-------+---------+----------+---------+-------+
           |     - |       - |        - |       - |     - |
           +-------+---------+----------+---------+-------+\n
           """
  end
end
