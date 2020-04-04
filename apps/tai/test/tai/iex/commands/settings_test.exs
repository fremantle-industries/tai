defmodule Tai.IEx.Commands.SettingsTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  setup do
    config =
      Tai.Config.parse()
      |> Map.put(:send_orders, true)

    start_supervised!({Tai.Settings, config})
    start_supervised!(Tai.Commander)
    :ok
  end

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
