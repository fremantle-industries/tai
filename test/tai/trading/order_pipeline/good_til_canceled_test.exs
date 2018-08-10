defmodule Tai.Trading.OrderPipeline.GoodTilCanceledTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Tai.TestSupport.Helpers

  setup do
    on_exit(fn ->
      Tai.Trading.OrderStore.clear()
    end)
  end

  describe "unfilled" do
    test "updates status to pending for buy orders" do
      log_msg =
        capture_log(fn ->
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
            %Tai.Trading.Order{status: :enqueued} = previous_order,
            %Tai.Trading.Order{status: :pending} = updated_order
          }

          assert previous_order.client_id == order.client_id
          assert previous_order.executed_size == Decimal.new(0)
          assert updated_order.client_id == order.client_id
          assert updated_order.executed_size == Decimal.new(0)
        end)

      assert log_msg =~ "order pending - client_id:"
    end

    test "updates status to pending for sell orders" do
      log_msg =
        capture_log(fn ->
          order =
            Tai.Trading.OrderPipeline.sell_limit(
              :test_exchange_a,
              :main,
              :btc_usd_pending,
              100_000.1,
              0.01,
              :gtc,
              fire_order_callback(self())
            )

          assert_receive {
            :callback_fired,
            %Tai.Trading.Order{status: :enqueued} = previous_order,
            %Tai.Trading.Order{status: :pending} = updated_order
          }

          assert previous_order.client_id == order.client_id
          assert previous_order.server_id == nil
          assert previous_order.executed_size == Decimal.new(0)
          assert updated_order.client_id == order.client_id
          assert updated_order.server_id != nil
          assert updated_order.executed_size == Decimal.new(0)
        end)

      assert log_msg =~ "order pending - client_id:"
    end
  end
end
