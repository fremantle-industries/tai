defmodule Tai.Trading.OrderPipeline.GoodTillCancelTest do
  use ExUnit.Case, async: false

  import Tai.TestSupport.Helpers
  alias Tai.TestSupport.Mocks

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    start_supervised!(Mocks.Server)
    {:ok, _} = Application.ensure_all_started(:tai)

    :ok
  end

  @venue_order_id "5adb3759-e45f-4d58-ad50-757b6a84ed7b"

  describe "unfilled buy" do
    setup do
      Mocks.Responses.Orders.GoodTillCancel.unfilled(
        @venue_order_id,
        %Tai.Trading.OrderSubmissions.BuyLimitGtc{
          venue_id: :test_exchange_a,
          account_id: :main,
          product_symbol: :btc_usd,
          price: Decimal.new("100.1"),
          qty: Decimal.new("0.1"),
          post_only: true
        }
      )
    end

    test "fires the callback" do
      Tai.Trading.OrderPipeline.enqueue(%Tai.Trading.OrderSubmissions.BuyLimitGtc{
        venue_id: :test_exchange_a,
        account_id: :main,
        product_symbol: :btc_usd,
        price: Decimal.new("100.1"),
        qty: Decimal.new("0.1"),
        post_only: false,
        order_updated_callback: fire_order_callback(self())
      })

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :enqueued},
        %Tai.Trading.Order{status: :open}
      }
    end

    test "broadcasts an event" do
      Tai.Events.firehose_subscribe()

      order =
        Tai.Trading.OrderPipeline.enqueue(%Tai.Trading.OrderSubmissions.BuyLimitGtc{
          venue_id: :test_exchange_a,
          account_id: :main,
          product_symbol: :btc_usd,
          price: Decimal.new("100.1"),
          qty: Decimal.new("0.1"),
          post_only: false
        })

      client_id = order.client_id

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{
                        client_id: ^client_id,
                        side: :buy,
                        status: :open
                      } = event}

      assert event.executed_size == Decimal.new(0)
    end
  end

  describe "unfilled sell" do
    setup do
      Mocks.Responses.Orders.GoodTillCancel.unfilled(
        @venue_order_id,
        %Tai.Trading.OrderSubmissions.SellLimitGtc{
          venue_id: :test_exchange_a,
          account_id: :main,
          product_symbol: :btc_usd,
          price: Decimal.new("100000.1"),
          qty: Decimal.new("0.01"),
          post_only: true
        }
      )
    end

    test "fires the callback" do
      Tai.Trading.OrderPipeline.enqueue(%Tai.Trading.OrderSubmissions.SellLimitGtc{
        venue_id: :test_exchange_a,
        account_id: :main,
        product_symbol: :btc_usd,
        price: Decimal.new("100000.1"),
        qty: Decimal.new("0.01"),
        post_only: false,
        order_updated_callback: fire_order_callback(self())
      })

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :enqueued} = previous_order,
        %Tai.Trading.Order{status: :open} = updated_order
      }
    end

    test "broadcasts an event" do
      Tai.Events.firehose_subscribe()

      order =
        Tai.Trading.OrderPipeline.enqueue(%Tai.Trading.OrderSubmissions.SellLimitGtc{
          venue_id: :test_exchange_a,
          account_id: :main,
          product_symbol: :btc_usd,
          price: Decimal.new("100000.1"),
          qty: Decimal.new("0.01"),
          post_only: false
        })

      client_id = order.client_id

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{
                        client_id: ^client_id,
                        side: :sell,
                        status: :open
                      } = event}

      assert event.executed_size == Decimal.new(0)
    end
  end
end
