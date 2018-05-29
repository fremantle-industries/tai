defmodule Tai.Trading.OrderPipeline.SkippedTest do
  use ExUnit.Case, async: false

  import Tai.TestSupport.Helpers

  setup do
    on_exit(fn ->
      restart_application()
    end)
  end

  test "changes the status to skip when sending orders is disabled" do
    Tai.Settings.disable_send_orders!()

    Tai.Trading.OrderPipeline.buy_limit(
      :test_exchange_a,
      :main,
      :btc_usd_pending,
      100.1,
      0.1,
      :gtc,
      fire_order_callback(self())
    )

    assert_receive {
      :callback_fired,
      %Tai.Trading.Order{status: :enqueued},
      %Tai.Trading.Order{status: :skip}
    }
  end
end
