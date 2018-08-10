defmodule Tai.Trading.OrderPipeline.EnqueueTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Tai.TestSupport.Helpers

  setup do
    on_exit(fn ->
      Tai.Trading.OrderStore.clear()
    end)
  end

  test "buy_limit enqueues an order and logs a message" do
    assert Tai.Trading.OrderStore.count() == 0

    log_msg =
      capture_log(fn ->
        order =
          Tai.Trading.OrderPipeline.buy_limit(
            :test_exchange_a,
            :main,
            :btc_usdt,
            100.1,
            0.1,
            :fok,
            fire_order_callback(self())
          )

        assert Tai.Trading.OrderStore.count() == 1
        assert order.status == Tai.Trading.OrderStatus.enqueued()
        assert order.price == Decimal.new(100.1)
        assert order.size == Decimal.new(0.1)
        assert order.time_in_force == Tai.Trading.TimeInForce.fill_or_kill()
        assert_receive {:callback_fired, nil, %Tai.Trading.Order{status: :enqueued}}
      end)

    assert log_msg =~ "order enqueued - client_id:"
  end

  test "sell_limit enqueues an order and logs a message" do
    assert Tai.Trading.OrderStore.count() == 0

    log_msg =
      capture_log(fn ->
        order =
          Tai.Trading.OrderPipeline.sell_limit(
            :test_exchange_a,
            :main,
            :btc_usdt,
            100_000.1,
            0.01,
            :fok,
            fire_order_callback(self())
          )

        assert Tai.Trading.OrderStore.count() == 1
        assert order.status == Tai.Trading.OrderStatus.enqueued()
        assert order.price == Decimal.new(100_000.1)
        assert order.size == Decimal.new(0.01)
        assert order.time_in_force == Tai.Trading.TimeInForce.fill_or_kill()
        assert_receive {:callback_fired, nil, %Tai.Trading.Order{status: :enqueued}}
      end)

    assert log_msg =~ "order enqueued - client_id:"
  end
end
