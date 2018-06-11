defmodule Tai.Trading.OrderPipeline.CancelTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  setup do
    on_exit(fn ->
      Tai.Trading.OrderStore.clear()
    end)

    test_pid = self()

    callback = fn previous_order, updated_order ->
      send(test_pid, {:callback_fired, previous_order, updated_order})
    end

    {:ok, callback: callback}
  end

  test "cancel updates the order status to :canceling and sends the request to the exchange in the background",
       %{callback: callback} do
    order =
      Tai.Trading.OrderPipeline.buy_limit(
        :test_account_a,
        :btcusd_pending,
        100.1,
        0.1,
        :gtc,
        callback
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

  test "cancel returns an error tuple when the order is not pending", %{callback: callback} do
    order =
      Tai.Trading.OrderPipeline.buy_limit(
        :test_account_a,
        :btcusd_expired,
        100.1,
        0.1,
        :gtc,
        callback
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

    assert log_msg =~ "could not cancel order client_id:"
    assert log_msg =~ "status must be 'pending' but it was 'error'"
  end
end
