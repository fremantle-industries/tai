defmodule Tai.Commands.Helper.StartAdvisorsTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  import Support.Advisors, only: [insert_spec: 2]

  @test_store_id __MODULE__

  setup do
    start_supervised!({Tai.Advisors.Supervisor, []})
    start_supervised!({Tai.Advisors.Store, id: @test_store_id})
    insert_spec(%{group_id: :group_a, advisor_id: :main}, @test_store_id)
    insert_spec(%{group_id: :group_b, advisor_id: :main}, @test_store_id)
    :ok
  end

  test "can start all advisors" do
    assert capture_io(fn -> Tai.Commands.Helper.start_advisors(store_id: @test_store_id) end) ==
             "Started advisors: 2 new, 0 already running\n"

    output = capture_io(fn -> Tai.Commands.Helper.advisors(store_id: @test_store_id) end)

    assert output =~ ~r/\|\s+group_a \|\s+main \|\s+running \|\s+#PID<.+> \|/
    assert output =~ ~r/\|\s+group_b \|\s+main \|\s+running \|\s+#PID<.+> \|/
  end

  test "can filter advisors to start by struct attributes" do
    assert capture_io(fn ->
             Tai.Commands.Helper.start_advisors(
               where: [group_id: :group_a],
               store_id: @test_store_id
             )
           end) ==
             "Started advisors: 1 new, 0 already running\n"

    output = capture_io(fn -> Tai.Commands.Helper.advisors(store_id: @test_store_id) end)

    assert output =~ ~r/\|\s+group_a \|\s+main \|\s+running \|\s+#PID<.+> \|/
    assert output =~ ~r/\|\s+group_b \|\s+main \|\s+unstarted \|\s+- \|/
  end
end
