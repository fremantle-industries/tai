defmodule Tai.IEx.Commands.StartAdvisorsTest do
  use Tai.TestSupport.DataCase, async: false
  import ExUnit.CaptureIO

  setup do
    mock_advisor_config(%{fleet_id: :fleet_a, advisor_id: :main})
    mock_advisor_config(%{fleet_id: :fleet_b, advisor_id: :main})
    :ok
  end

  test "can start all advisors" do
    assert capture_io(&Tai.IEx.start_advisors/0) ==
             "started advisors new=2, already_running=0\n"

    output = capture_io(&Tai.IEx.advisors/0)

    assert output =~ ~r/\|\s+fleet_a \|\s+main \|\s+running \|\s+#PID<.+> \|/
    assert output =~ ~r/\|\s+fleet_b \|\s+main \|\s+running \|\s+#PID<.+> \|/
  end

  test "can filter advisors to start by struct attributes" do
    assert capture_io(fn -> Tai.IEx.start_advisors(where: [fleet_id: :fleet_a]) end) ==
             "started advisors new=1, already_running=0\n"

    output = capture_io(&Tai.IEx.advisors/0)

    assert output =~ ~r/\|\s+fleet_a \|\s+main \|\s+running \|\s+#PID<.+> \|/
    assert output =~ ~r/\|\s+fleet_b \|\s+main \|\s+unstarted \|\s+- \|/
  end
end
