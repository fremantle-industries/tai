defmodule Tai.IEx.Commands.HelpTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  test "show command usage" do
    assert capture_io(&Tai.IEx.help/0) != ""
  end
end
