defmodule Tai.Commands.Helper.HelpTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  test "show command usage" do
    assert capture_io(&Tai.Commands.Helper.help/0) != ""
  end
end
