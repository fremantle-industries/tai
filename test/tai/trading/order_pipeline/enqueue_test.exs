defmodule Tai.Trading.OrderPipeline.EnqueueTest do
  use ExUnit.Case, async: false

  import Tai.TestSupport.Helpers

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  describe "buy_limit" do
    setup do
      Tai.Events.firehose_subscribe()
      assert Tai.Trading.OrderStore.count() == 0

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

      {:ok, %{client_id: order.client_id}}
    end

    test "adds an order to the store and fires the callback", %{client_id: client_id} do
      assert_receive {Tai.Event, %Tai.Events.OrderUpdated{client_id: ^client_id}}
      assert Tai.Trading.OrderStore.count() == 1
      assert_receive {:callback_fired, nil, %Tai.Trading.Order{status: :enqueued}}
    end

    test "broadcasts an event with the submissions details", %{client_id: client_id} do
      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{
                        client_id: ^client_id,
                        status: :enqueued,
                        venue_id: :test_exchange_a,
                        account_id: :main,
                        product_symbol: :btc_usd,
                        side: :buy,
                        type: :limit,
                        time_in_force: :fok
                      } = event}

      assert event.price == Decimal.new(100.1)
      assert event.size == Decimal.new(0.1)
    end
  end

  describe "sell limit" do
    setup do
      Tai.Events.firehose_subscribe()
      assert Tai.Trading.OrderStore.count() == 0

      order =
        Tai.Trading.OrderPipeline.sell_limit(
          :test_exchange_a,
          :main,
          :ltc_usd,
          100_000.1,
          0.01,
          :ioc,
          fire_order_callback(self())
        )

      {:ok, %{client_id: order.client_id}}
    end

    test "adds an order to the store and fires the callback", %{client_id: client_id} do
      assert_receive {Tai.Event, %Tai.Events.OrderUpdated{client_id: ^client_id}}
      assert Tai.Trading.OrderStore.count() == 1
      assert_receive {:callback_fired, nil, %Tai.Trading.Order{status: :enqueued}}
    end

    test "broadcasts an event with the submissions details", %{client_id: client_id} do
      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{
                        client_id: ^client_id,
                        status: :enqueued,
                        venue_id: :test_exchange_a,
                        account_id: :main,
                        product_symbol: :ltc_usd,
                        side: :sell,
                        type: :limit,
                        time_in_force: :ioc
                      } = event}

      assert event.price == Decimal.new(100_000.1)
      assert event.size == Decimal.new(0.01)
    end
  end
end
