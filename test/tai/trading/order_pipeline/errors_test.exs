defmodule Tai.Trading.OrderPipeline.ErrorsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Tai.TestSupport.Helpers

  setup do
    on_exit(fn ->
      Tai.Trading.OrderStore.clear()
    end)

    start_supervised!(Tai.TestSupport.Mocks.Server)
    :ok
  end

  test "records the error and its reason" do
    log_msg =
      capture_log(fn ->
        order =
          Tai.Trading.OrderPipeline.buy_limit(
            :test_exchange_a,
            :main,
            :btc_usd,
            100.1,
            0.1,
            :fok,
            fire_order_callback(self())
          )

        assert_receive {
          :callback_fired,
          %Tai.Trading.Order{status: :enqueued} = previous_order,
          %Tai.Trading.Order{status: :error} = updated_order
        }

        assert previous_order.client_id == order.client_id
        assert previous_order.error_reason == nil
        assert updated_order.client_id == order.client_id
        assert updated_order.error_reason == :mock_not_found
      end)

    assert log_msg =~
             ~r/\[order:.{36,36},error,test_exchange_a,main,btc_usd,buy,limit,fok,100.1,0.1,mock_not_found\]/
  end
end
