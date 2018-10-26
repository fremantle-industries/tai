defmodule Tai.Trading.OrderPipeline.EnqueueTest do
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

  test "buy_limit enqueues an order and logs a message" do
    assert Tai.Trading.OrderStore.count() == 0

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

        assert Tai.Trading.OrderStore.count() == 1
        assert order.status == Tai.Trading.OrderStatus.enqueued()
        assert order.price == Decimal.new(100.1)
        assert order.size == Decimal.new(0.1)
        assert order.time_in_force == Tai.Trading.TimeInForce.fill_or_kill()
        assert_receive {:callback_fired, nil, %Tai.Trading.Order{status: :enqueued}}
      end)

    assert log_msg =~
             ~r/\[order:.{36,36},enqueued,test_exchange_a,main,btc_usd_success,buy,limit,fok,100.1,0.1,\]/
  end

  test "sell_limit enqueues an order and logs a message" do
    assert Tai.Trading.OrderStore.count() == 0

    log_msg =
      capture_log(fn ->
        order =
          Tai.Trading.OrderPipeline.sell_limit(
            :test_exchange_a,
            :main,
            :btc_usd_success,
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

    assert log_msg =~
             ~r/\[order:.{36,36},enqueued,test_exchange_a,main,btc_usd_success,sell,limit,fok,100000.1,0.01,\]/
  end
end
