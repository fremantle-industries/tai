defmodule Tai.Commands.StopAdvisorsTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  import Support.Advisors, only: [insert_spec: 2]

  @test_store_id __MODULE__

  setup do
    start_supervised!({Tai.Advisors.Supervisor, []})
    start_supervised!({Tai.Advisors.SpecStore, id: @test_store_id})
    insert_spec(%{group_id: :group_a, advisor_id: :main}, @test_store_id)
    insert_spec(%{group_id: :group_b, advisor_id: :main}, @test_store_id)
    capture_io(fn -> Tai.CommandsHelper.start_advisors(store_id: @test_store_id) end)
    :ok
  end

  test "can stop all advisors" do
    assert capture_io(fn -> Tai.CommandsHelper.stop_advisors(store_id: @test_store_id) end) ==
             "Stopped advisors: 2 new, 0 already stopped\n"

    output = capture_io(fn -> Tai.CommandsHelper.advisors(store_id: @test_store_id) end)

    assert output =~ ~r/\|\s+group_a \|\s+main \|\s+unstarted \|\s+- \|/
    assert output =~ ~r/\|\s+group_b \|\s+main \|\s+unstarted \|\s+- \|/
  end

  test "can filter advisors to stop by struct attributes" do
    assert capture_io(fn ->
             Tai.CommandsHelper.stop_advisors(
               where: [group_id: :group_a],
               store_id: @test_store_id
             )
           end) ==
             "Stopped advisors: 1 new, 0 already stopped\n"

    output = capture_io(fn -> Tai.CommandsHelper.advisors(store_id: @test_store_id) end)

    assert output =~ ~r/\|\s+group_a \|\s+main \|\s+unstarted \|\s+- \|/
    assert output =~ ~r/\|\s+group_b \|\s+main \|\s+running \|\s+#PID<.+> \|/
  end
end
