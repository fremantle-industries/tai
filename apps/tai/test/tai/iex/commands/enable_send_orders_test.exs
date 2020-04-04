defmodule Tai.IEx.Commands.EnableSendOrdersTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  setup do
    config =
      Tai.Config.parse()
      |> Map.put(:send_orders, false)

    start_supervised!({Tai.Settings, config})
    start_supervised!(Tai.Commander)
    :ok
  end

  test "enable_send_orders sets the value to true" do
    assert capture_io(&Tai.IEx.enable_send_orders/0) == "ok\n"
  end
end
