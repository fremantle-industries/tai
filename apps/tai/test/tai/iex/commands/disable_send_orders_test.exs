defmodule Tai.IEx.Commands.DisableSendOrdersTest do
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

  test "disable_send_orders sets the value to false" do
    assert capture_io(&Tai.IEx.disable_send_orders/0) == "ok\n"
  end
end
