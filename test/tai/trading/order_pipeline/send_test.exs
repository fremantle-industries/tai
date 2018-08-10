defmodule Tai.Trading.OrderPipeline.SendTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Tai.TestSupport.Factories.Order

  test "logs a warning when the order is not buy or sell limit" do
    log_msg =
      capture_log(fn ->
        build_invalid_order()
        |> Tai.Trading.OrderPipeline.Send.call()
      end)

    assert log_msg =~ "order error - client_id:"
    assert log_msg =~ ", cannot send unhandled order type 'invalid_side invalid_type'"
  end
end
