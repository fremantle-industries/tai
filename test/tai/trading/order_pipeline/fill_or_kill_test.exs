defmodule Tai.Trading.OrderPipeline.FillOrKillTest do
  use ExUnit.Case, async: false

  import Tai.TestSupport.Helpers
  alias Tai.TestSupport.Mocks
  alias Tai.Trading.OrderPipeline

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    start_supervised!(Tai.TestSupport.Mocks.Server)
    {:ok, _} = Application.ensure_all_started(:tai)

    :ok
  end

  describe "unfilled buy" do
    setup do
      Mocks.Orders.FillOrKill.expired(
        symbol: :btc_usd,
        price: Decimal.new("100.1"),
        original_size: Decimal.new("0.1")
      )
    end

    test "fires the callback when the status changes to expired" do
      OrderPipeline.enqueue(%Tai.Trading.Orders.BuyLimit{
        venue_id: :test_exchange_a,
        account_id: :main,
        product_symbol: :btc_usd,
        price: 100.1,
        qty: 0.1,
        time_in_force: :fok,
        order_updated_callback: fire_order_callback(self())
      })

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{side: :buy, status: :enqueued},
        %Tai.Trading.Order{side: :buy, status: :expired}
      }
    end

    test "broadcasts an event with no size executed" do
      Tai.Events.firehose_subscribe()

      order =
        OrderPipeline.enqueue(%Tai.Trading.Orders.BuyLimit{
          venue_id: :test_exchange_a,
          account_id: :main,
          product_symbol: :btc_usd,
          price: 100.1,
          qty: 0.1,
          time_in_force: :fok
        })

      client_id = order.client_id

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{
                        client_id: ^client_id,
                        side: :buy,
                        status: :expired
                      } = event}

      assert event.executed_size == Decimal.new(0)
    end
  end

  describe "unfilled sell" do
    setup do
      Mocks.Orders.FillOrKill.expired(
        symbol: :btc_usd,
        price: Decimal.new("10000.1"),
        original_size: Decimal.new("0.1")
      )
    end

    test "fires the callback when the status changes to expired" do
      OrderPipeline.enqueue(%Tai.Trading.Orders.SellLimit{
        venue_id: :test_exchange_a,
        account_id: :main,
        product_symbol: :btc_usd,
        price: 10_000.1,
        qty: 0.1,
        time_in_force: :fok,
        order_updated_callback: fire_order_callback(self())
      })

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{side: :sell, status: :enqueued},
        %Tai.Trading.Order{side: :sell, status: :expired}
      }
    end

    test "broadcasts an event with no size executed" do
      Tai.Events.firehose_subscribe()

      order =
        OrderPipeline.enqueue(%Tai.Trading.Orders.SellLimit{
          venue_id: :test_exchange_a,
          account_id: :main,
          product_symbol: :btc_usd,
          price: 10_000.1,
          qty: 0.1,
          time_in_force: :fok
        })

      client_id = order.client_id

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{
                        client_id: ^client_id,
                        side: :sell,
                        status: :expired
                      } = event}

      assert event.executed_size == Decimal.new(0)
    end
  end

  describe "filled buy" do
    setup do
      Mocks.Orders.FillOrKill.filled(
        symbol: :btc_usd,
        price: Decimal.new("100.1"),
        original_size: Decimal.new("0.1")
      )
    end

    test "fires the callback" do
      OrderPipeline.enqueue(%Tai.Trading.Orders.BuyLimit{
        venue_id: :test_exchange_a,
        account_id: :main,
        product_symbol: :btc_usd,
        price: 100.1,
        qty: 0.1,
        time_in_force: :fok,
        order_updated_callback: fire_order_callback(self())
      })

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{side: :buy, status: :enqueued},
        %Tai.Trading.Order{side: :buy, status: :filled}
      }
    end

    test "broadcasts an event with the executed size" do
      Tai.Events.firehose_subscribe()

      order =
        OrderPipeline.enqueue(%Tai.Trading.Orders.BuyLimit{
          venue_id: :test_exchange_a,
          account_id: :main,
          product_symbol: :btc_usd,
          price: 100.1,
          qty: 0.1,
          time_in_force: :fok
        })

      client_id = order.client_id

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{
                        client_id: ^client_id,
                        side: :buy,
                        status: :filled
                      } = event}

      assert event.executed_size == Decimal.new("0.1")
    end
  end

  describe "filled sell" do
    setup do
      Mocks.Orders.FillOrKill.filled(
        symbol: :btc_usd,
        price: Decimal.new("10000.1"),
        original_size: Decimal.new("0.1")
      )
    end

    test "fires the callback" do
      OrderPipeline.enqueue(%Tai.Trading.Orders.SellLimit{
        venue_id: :test_exchange_a,
        account_id: :main,
        product_symbol: :btc_usd,
        price: 10_000.1,
        qty: 0.1,
        time_in_force: :fok,
        order_updated_callback: fire_order_callback(self())
      })

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{side: :sell, status: :enqueued},
        %Tai.Trading.Order{side: :sell, status: :filled}
      }
    end

    test "broadcasts an event with the executed size" do
      Tai.Events.firehose_subscribe()

      order =
        OrderPipeline.enqueue(%Tai.Trading.Orders.SellLimit{
          venue_id: :test_exchange_a,
          account_id: :main,
          product_symbol: :btc_usd,
          price: 10_000.1,
          qty: 0.1,
          time_in_force: :fok
        })

      client_id = order.client_id

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{
                        client_id: ^client_id,
                        side: :sell,
                        status: :filled
                      } = event}

      assert event.executed_size == Decimal.new("0.1")
    end
  end
end
