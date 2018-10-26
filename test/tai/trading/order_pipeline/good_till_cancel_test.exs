defmodule Tai.Trading.OrderPipeline.GoodTillCancelTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Tai.TestSupport.Helpers

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    start_supervised!(Tai.TestSupport.Mocks.Server)
    :ok
  end

  describe "unfilled" do
    test "updates status to pending for buy orders" do
      log_msg =
        capture_log(fn ->
          Tai.TestSupport.Mocks.Orders.GoodTillCancel.unfilled(
            server_id: "UNFILLED_ORDER_SERVER_ID",
            symbol: :btc_usd,
            price: Decimal.new(100.1),
            original_size: Decimal.new(0.1)
          )

          order =
            Tai.Trading.OrderPipeline.buy_limit(
              :test_exchange_a,
              :main,
              :btc_usd,
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

      assert log_msg =~
               ~r/\[order:.{36,36},pending,test_exchange_a,main,btc_usd,buy,limit,gtc,100.1,0.1,\]/
    end

    test "updates status to pending for sell orders" do
      log_msg =
        capture_log(fn ->
          Tai.TestSupport.Mocks.Orders.GoodTillCancel.unfilled(
            server_id: "UNFILLED_ORDER_SERVER_ID",
            symbol: :btc_usd,
            price: Decimal.new(100_000.1),
            original_size: Decimal.new(0.01)
          )

          order =
            Tai.Trading.OrderPipeline.sell_limit(
              :test_exchange_a,
              :main,
              :btc_usd,
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

      assert log_msg =~
               ~r/\[order:.{36,36},pending,test_exchange_a,main,btc_usd,sell,limit,gtc,100000.1,0.01,\]/
    end
  end
end
