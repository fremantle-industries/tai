defmodule Tai.Trading.OrderPipeline.SkippedTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Tai.TestSupport.Helpers

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test "skips buy limit orders" do
    Tai.Settings.disable_send_orders!()

    log_msg =
      capture_log(fn ->
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
      end)

    assert log_msg =~
             ~r/\[order:.{36,36},skip,test_exchange_a,main,btc_usd_pending,buy,limit,gtc,100.1,0.1,\]/
  end

  test "skips sell limit orders" do
    Tai.Settings.disable_send_orders!()

    log_msg =
      capture_log(fn ->
        Tai.Trading.OrderPipeline.sell_limit(
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
      end)

    assert log_msg =~
             ~r/\[order:.{36,36},skip,test_exchange_a,main,btc_usd_pending,sell,limit,gtc,100.1,0.1,\]/
  end
end
