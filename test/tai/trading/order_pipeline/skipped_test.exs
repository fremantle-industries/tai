defmodule Tai.Trading.OrderPipeline.SkippedTest do
  use ExUnit.Case, async: false

  import Tai.TestSupport.Helpers
  alias Tai.Trading.OrderPipeline

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    Tai.Settings.disable_send_orders!()

    :ok
  end

  describe "buy" do
    test "fires the callback" do
      OrderPipeline.enqueue(%Tai.Trading.OrderSubmissions.BuyLimitGtc{
        venue_id: :test_exchange_a,
        account_id: :main,
        product_symbol: :btc_usd_open,
        price: Decimal.new("100.1"),
        qty: Decimal.new("0.1"),
        post_only: false,
        order_updated_callback: fire_order_callback(self())
      })

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{side: :buy, status: :enqueued},
        %Tai.Trading.Order{side: :buy, status: :skip}
      }
    end

    test "broadcasts an event" do
      Tai.Events.firehose_subscribe()

      order =
        OrderPipeline.enqueue(%Tai.Trading.OrderSubmissions.BuyLimitGtc{
          venue_id: :test_exchange_a,
          account_id: :main,
          product_symbol: :btc_usd_open,
          price: Decimal.new("100.1"),
          qty: Decimal.new("0.1"),
          post_only: false
        })

      client_id = order.client_id

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{
                        client_id: ^client_id,
                        side: :buy,
                        status: :skip
                      }}
    end
  end

  describe "sell" do
    test "fires the callback" do
      OrderPipeline.enqueue(%Tai.Trading.OrderSubmissions.SellLimitGtc{
        venue_id: :test_exchange_a,
        account_id: :main,
        product_symbol: :btc_usd_open,
        price: Decimal.new("100.1"),
        qty: Decimal.new("0.1"),
        post_only: false,
        order_updated_callback: fire_order_callback(self())
      })

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{side: :sell, status: :enqueued},
        %Tai.Trading.Order{side: :sell, status: :skip}
      }
    end

    test "broadcasts an event" do
      Tai.Events.firehose_subscribe()

      order =
        OrderPipeline.enqueue(%Tai.Trading.OrderSubmissions.SellLimitGtc{
          venue_id: :test_exchange_a,
          account_id: :main,
          product_symbol: :btc_usd_open,
          price: Decimal.new("100.1"),
          qty: Decimal.new("0.1"),
          post_only: false
        })

      client_id = order.client_id

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{
                        client_id: ^client_id,
                        side: :sell,
                        status: :skip
                      }}
    end
  end
end
