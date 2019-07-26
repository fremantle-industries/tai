defmodule Tai.Commands.HelpTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  test "show command usage" do
    assert capture_io(&Tai.CommandsHelper.help/0) != ""
  end
end
