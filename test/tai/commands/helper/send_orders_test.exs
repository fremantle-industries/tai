defmodule Tai.Commands.Helper.SendOrdersTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test "disable_send_orders sets the value to false" do
    assert capture_io(&Tai.Commands.Helper.disable_send_orders/0) == """
           +-------------+-------+
           |        Name | Value |
           +-------------+-------+
           | send_orders | false |
           +-------------+-------+\n
           """
  end

  test "enable_send_orders sets the value to false" do
    Tai.Settings.disable_send_orders!()

    assert capture_io(&Tai.Commands.Helper.enable_send_orders/0) == """
           +-------------+-------+
           |        Name | Value |
           +-------------+-------+
           | send_orders |  true |
           +-------------+-------+\n
           """
  end
end
