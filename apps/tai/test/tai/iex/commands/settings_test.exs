defmodule Tai.IEx.Commands.SettingsTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai_events)
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
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
