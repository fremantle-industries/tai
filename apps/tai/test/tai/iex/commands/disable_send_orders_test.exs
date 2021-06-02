defmodule Tai.IEx.Commands.DisableSendOrdersTest do
  use Tai.TestSupport.DataCase, async: false
  import ExUnit.CaptureIO

  test "disable_send_orders sets the value to false" do
    assert capture_io(&Tai.IEx.settings/0) == """
           +-------------+-------+
           |        Name | Value |
           +-------------+-------+
           | send_orders |  true |
           +-------------+-------+\n
           """

    assert capture_io(&Tai.IEx.disable_send_orders/0) == "ok\n"

    assert capture_io(&Tai.IEx.settings/0) == """
           +-------------+-------+
           |        Name | Value |
           +-------------+-------+
           | send_orders | false |
           +-------------+-------+\n
           """
  end
end
