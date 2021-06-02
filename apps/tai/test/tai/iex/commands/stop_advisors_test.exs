defmodule Tai.IEx.Commands.StopAdvisorsTest do
  use Tai.TestSupport.DataCase, async: false
  import ExUnit.CaptureIO
  import Support.Advisors, only: [insert_spec: 1]

  setup do
    insert_spec(%{group_id: :group_a, advisor_id: :main})
    insert_spec(%{group_id: :group_b, advisor_id: :main})

    capture_io(&Tai.IEx.start_advisors/0)

    :ok
  end

  test "can stop all advisors" do
    assert capture_io(&Tai.IEx.stop_advisors/0) ==
             "Stopped advisors: 2 new, 0 already stopped\n"

    output = capture_io(&Tai.IEx.advisors/0)

    assert output =~ ~r/\|\s+group_a \|\s+main \|\s+unstarted \|\s+- \|/
    assert output =~ ~r/\|\s+group_b \|\s+main \|\s+unstarted \|\s+- \|/
  end

  test "can filter advisors to stop by struct attributes" do
    assert capture_io(fn -> Tai.IEx.stop_advisors(where: [group_id: :group_a]) end) ==
             "Stopped advisors: 1 new, 0 already stopped\n"

    output = capture_io(&Tai.IEx.advisors/0)

    assert output =~ ~r/\|\s+group_a \|\s+main \|\s+unstarted \|\s+- \|/
    assert output =~ ~r/\|\s+group_b \|\s+main \|\s+running \|\s+#PID<.+> \|/
  end
end
