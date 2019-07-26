defmodule Tai.Commands.SettingsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test "settings displays the current values" do
    assert capture_io(&Tai.CommandsHelper.settings/0) == """
           +-------------+-------+
           |        Name | Value |
           +-------------+-------+
           | send_orders |  true |
           +-------------+-------+\n
           """
  end
end
