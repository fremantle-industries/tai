defmodule Tai.IEx.Commands.SettingsTest do
  use Tai.TestSupport.DataCase, async: false
  import ExUnit.CaptureIO

  test "settings displays the current values" do
    assert capture_io(&Tai.IEx.settings/0) == """
           +-------------+-------+
           |        Name | Value |
           +-------------+-------+
           | send_orders |  true |
           +-------------+-------+\n
           """
  end
end
