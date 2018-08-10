defmodule Tai.Trading.OrderPipeline.CancelTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Tai.TestSupport.Helpers

  setup do
    on_exit(fn ->
      Tai.Trading.OrderStore.clear()
    end)
  end

  test "updates the status to canceling and sends the request to the exchange in the background" do
    order =
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
      %Tai.Trading.Order{status: :pending}
    }

    log_msg =
      capture_log(fn ->
        assert {:ok, %Tai.Trading.Order{status: :canceling}} =
                 Tai.Trading.OrderPipeline.cancel(order)

        assert_receive {
          :callback_fired,
          %Tai.Trading.Order{status: :pending},
          %Tai.Trading.Order{status: :canceling}
        }

        assert_receive {
          :callback_fired,
          %Tai.Trading.Order{status: :canceling},
          %Tai.Trading.Order{status: :canceled}
        }
      end)

    assert log_msg =~ "order canceling - client_id:"
    assert log_msg =~ "order canceled - client_id:"
  end

  test "returns an error tuple when the status is not pending" do
    order =
      Tai.Trading.OrderPipeline.buy_limit(
        :test_exchange_a,
        :main,
        :btc_usd_expired,
        100.1,
        0.1,
        :gtc,
        fire_order_callback(self())
      )

    assert_receive {
      :callback_fired,
      %Tai.Trading.Order{status: :enqueued},
      %Tai.Trading.Order{status: :error}
    }

    log_msg =
      capture_log(fn ->
        assert {:error, :order_status_must_be_pending} = Tai.Trading.OrderPipeline.cancel(order)
      end)

    assert log_msg =~
             ~r/could not cancel order client_id: .+ status must be 'pending' but it was 'error'/
  end
end
