defmodule Tai.IEx.Commands.SendOrdersTest do
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

  test "disable_send_orders sets the value to false" do
    assert capture_io(&Tai.IEx.disable_send_orders/0) == """
           +-------------+-------+
           |        Name | Value |
           +-------------+-------+
           | send_orders | false |
           +-------------+-------+\n
           """
  end

  test "enable_send_orders sets the value to false" do
    Tai.Settings.disable_send_orders!()

    assert capture_io(&Tai.IEx.enable_send_orders/0) == """
           +-------------+-------+
           |        Name | Value |
           +-------------+-------+
           | send_orders |  true |
           +-------------+-------+\n
           """
  end
end
