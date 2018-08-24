defmodule Tai.Trading.OrderPipeline.FillOrKillTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Tai.TestSupport.Helpers

  setup do
    on_exit(fn ->
      Tai.Trading.OrderStore.clear()
    end)
  end

  describe "unfilled" do
    test "expires buy orders" do
      log_msg =
        capture_log(fn ->
          order =
            Tai.Trading.OrderPipeline.buy_limit(
              :test_exchange_a,
              :main,
              :btc_usd_expired,
              100.1,
              0.1,
              :fok,
              fire_order_callback(self())
            )

          assert_receive {
            :callback_fired,
            %Tai.Trading.Order{status: :enqueued} = previous_order,
            %Tai.Trading.Order{status: :expired} = updated_order
          }

          assert previous_order.client_id == order.client_id
          assert previous_order.executed_size == Decimal.new(0)
          assert updated_order.client_id == order.client_id
          assert updated_order.executed_size == Decimal.new(0)
        end)

      assert log_msg =~
               ~r/\[order:.{36,36},expired,test_exchange_a,main,btc_usd_expired,buy,limit,fok,100.1,0.1,\]/
    end

    test "expires sell orders" do
      log_msg =
        capture_log(fn ->
          order =
            Tai.Trading.OrderPipeline.sell_limit(
              :test_exchange_a,
              :main,
              :btc_usd_expired,
              10_000.1,
              0.1,
              :fok,
              fire_order_callback(self())
            )

          assert_receive {
            :callback_fired,
            %Tai.Trading.Order{status: :enqueued} = previous_order,
            %Tai.Trading.Order{status: :expired} = updated_order
          }

          assert previous_order.client_id == order.client_id
          assert previous_order.executed_size == Decimal.new(0)
          assert updated_order.client_id == order.client_id
          assert updated_order.executed_size == Decimal.new(0)
        end)

      assert log_msg =~
               ~r/\[order:.{36,36},expired,test_exchange_a,main,btc_usd_expired,sell,limit,fok,10000.1,0.1,\]/
    end
  end

  describe "executed" do
    test "updates the filled quantity of buy orders" do
      log_msg =
        capture_log(fn ->
          order =
            Tai.Trading.OrderPipeline.buy_limit(
              :test_exchange_a,
              :main,
              :btc_usd_success,
              100.1,
              0.1,
              :fok,
              fire_order_callback(self())
            )

          assert_receive {
            :callback_fired,
            %Tai.Trading.Order{status: :enqueued} = previous_order,
            %Tai.Trading.Order{status: :filled} = updated_order
          }

          assert previous_order.client_id == order.client_id
          assert previous_order.executed_size == Decimal.new(0)
          assert updated_order.client_id == order.client_id
          assert updated_order.executed_size == Decimal.new(0.1)
        end)

      assert log_msg =~
               ~r/\[order:.{36,36},filled,test_exchange_a,main,btc_usd_success,buy,limit,fok,100.1,0.1,\]/
    end

    test "updates the filled quantity of sell orders" do
      log_msg =
        capture_log(fn ->
          order =
            Tai.Trading.OrderPipeline.sell_limit(
              :test_exchange_a,
              :main,
              :btc_usd_success,
              10_000.1,
              0.1,
              :fok,
              fire_order_callback(self())
            )

          assert_receive {
            :callback_fired,
            %Tai.Trading.Order{status: :enqueued} = previous_order,
            %Tai.Trading.Order{status: :filled} = updated_order
          }

          assert previous_order.client_id == order.client_id
          assert previous_order.executed_size == Decimal.new(0)
          assert updated_order.client_id == order.client_id
          assert updated_order.executed_size == Decimal.new(0.1)
        end)

      assert log_msg =~
               ~r/\[order:.{36,36},filled,test_exchange_a,main,btc_usd_success,sell,limit,fok,10000.1,0.1,\]/
    end
  end
end
