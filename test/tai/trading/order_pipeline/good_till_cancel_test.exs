defmodule Tai.Trading.OrderPipeline.GoodTillCancelTest do
  use ExUnit.Case, async: false

  import Tai.TestSupport.Helpers

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    start_supervised!(Tai.TestSupport.Mocks.Server)
    {:ok, _} = Application.ensure_all_started(:tai)

    :ok
  end

  @server_id "UNFILLED_ORDER_SERVER_ID"

  describe "unfilled buy" do
    setup do
      Tai.TestSupport.Mocks.Orders.GoodTillCancel.unfilled(
        server_id: @server_id,
        symbol: :btc_usd,
        price: Decimal.new("100.1"),
        original_size: Decimal.new("0.1")
      )
    end

    test "fires the callback" do
      Tai.Trading.OrderPipeline.enqueue(%Tai.Trading.Orders.BuyLimit{
        venue_id: :test_exchange_a,
        account_id: :main,
        product_symbol: :btc_usd,
        price: 100.1,
        qty: 0.1,
        time_in_force: :gtc,
        order_updated_callback: fire_order_callback(self())
      })

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :enqueued},
        %Tai.Trading.Order{status: :pending}
      }
    end

    test "broadcasts an event" do
      Tai.Events.firehose_subscribe()

      order =
        Tai.Trading.OrderPipeline.enqueue(%Tai.Trading.Orders.BuyLimit{
          venue_id: :test_exchange_a,
          account_id: :main,
          product_symbol: :btc_usd,
          price: 100.1,
          qty: 0.1,
          time_in_force: :gtc
        })

      client_id = order.client_id

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{
                        client_id: ^client_id,
                        side: :buy,
                        status: :pending
                      } = event}

      assert event.executed_size == Decimal.new(0)
    end
  end

  describe "unfilled sell" do
    setup do
      Tai.TestSupport.Mocks.Orders.GoodTillCancel.unfilled(
        server_id: @server_id,
        symbol: :btc_usd,
        price: Decimal.new("100000.1"),
        original_size: Decimal.new("0.01")
      )
    end

    test "fires the callback" do
      Tai.Trading.OrderPipeline.enqueue(%Tai.Trading.Orders.SellLimit{
        venue_id: :test_exchange_a,
        account_id: :main,
        product_symbol: :btc_usd,
        price: 100_000.1,
        qty: 0.01,
        time_in_force: :gtc,
        order_updated_callback: fire_order_callback(self())
      })

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :enqueued} = previous_order,
        %Tai.Trading.Order{status: :pending} = updated_order
      }
    end

    test "broadcasts an event" do
      Tai.Events.firehose_subscribe()

      order =
        Tai.Trading.OrderPipeline.enqueue(%Tai.Trading.Orders.SellLimit{
          venue_id: :test_exchange_a,
          account_id: :main,
          product_symbol: :btc_usd,
          price: 100_000.1,
          qty: 0.01,
          time_in_force: :gtc
        })

      client_id = order.client_id

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{
                        client_id: ^client_id,
                        side: :sell,
                        status: :pending
                      } = event}

      assert event.executed_size == Decimal.new(0)
    end
  end
end
