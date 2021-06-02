defmodule Tai.IEx.Commands.EnableSendOrdersTest do
  use Tai.TestSupport.DataCase, async: false
  import ExUnit.CaptureIO

  test "enable_send_orders sets the value to true" do
    assert capture_io(&Tai.IEx.disable_send_orders/0) == "ok\n"
    assert capture_io(&Tai.IEx.settings/0) == """
           +-------------+-------+
           |        Name | Value |
           +-------------+-------+
           | send_orders | false |
           +-------------+-------+\n
           """

    assert capture_io(&Tai.IEx.enable_send_orders/0) == "ok\n"

    assert capture_io(&Tai.IEx.settings/0) == """
           +-------------+-------+
           |        Name | Value |
           +-------------+-------+
           | send_orders |  true |
           +-------------+-------+\n
           """
  end
end
