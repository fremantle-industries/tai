defmodule Tai.IEx.Commands.StartAdvisorsTest do
  use Tai.TestSupport.DataCase, async: false
  import ExUnit.CaptureIO
  import Support.Advisors, only: [insert_spec: 1]

  setup do
    insert_spec(%{group_id: :group_a, advisor_id: :main})
    insert_spec(%{group_id: :group_b, advisor_id: :main})
    :ok
  end

  test "can start all advisors" do
    assert capture_io(&Tai.IEx.start_advisors/0) ==
             "Started advisors: 2 new, 0 already running\n"

    output = capture_io(&Tai.IEx.advisors/0)

    assert output =~ ~r/\|\s+group_a \|\s+main \|\s+running \|\s+#PID<.+> \|/
    assert output =~ ~r/\|\s+group_b \|\s+main \|\s+running \|\s+#PID<.+> \|/
  end

  test "can filter advisors to start by struct attributes" do
    assert capture_io(fn -> Tai.IEx.start_advisors(where: [group_id: :group_a]) end) ==
             "Started advisors: 1 new, 0 already running\n"

    output = capture_io(&Tai.IEx.advisors/0)

    assert output =~ ~r/\|\s+group_a \|\s+main \|\s+running \|\s+#PID<.+> \|/
    assert output =~ ~r/\|\s+group_b \|\s+main \|\s+unstarted \|\s+- \|/
  end
end
