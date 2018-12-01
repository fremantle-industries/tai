defmodule Tai.Trading.OrderPipeline.CancelTest do
  use ExUnit.Case, async: false

  import Tai.TestSupport.Helpers
  alias Tai.Trading.OrderPipeline
  alias Tai.TestSupport.Mocks

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    start_supervised!(Tai.TestSupport.Mocks.Server)
    {:ok, _} = Application.ensure_all_started(:tai)

    :ok
  end

  describe "success" do
    @server_id "UNFILLED_ORDER_SERVER_ID"

    setup do
      Mocks.Orders.GoodTillCancel.unfilled(
        server_id: @server_id,
        symbol: :btc_usd,
        price: Decimal.new("100.1"),
        original_size: Decimal.new("0.1")
      )

      order =
        OrderPipeline.enqueue(%Tai.Trading.Orders.BuyLimit{
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

      {:ok, %{order: order}}
    end

    test "executes the callback when the status is updated",
         %{order: order} do
      Mocks.Orders.GoodTillCancel.canceled(server_id: @server_id)

      assert {:ok, %Tai.Trading.Order{status: :canceling}} = OrderPipeline.cancel(order)

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :pending},
        %Tai.Trading.Order{status: :canceling}
      }

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :canceling},
        %Tai.Trading.Order{status: :canceled}
      }
    end

    test "broadcasts updated events when the status changes",
         %{order: order} do
      Tai.Events.firehose_subscribe()

      Mocks.Orders.GoodTillCancel.canceled(server_id: @server_id)

      assert {:ok, %Tai.Trading.Order{status: :canceling}} = OrderPipeline.cancel(order)

      client_id = order.client_id

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{
                        client_id: ^client_id,
                        venue_id: :test_exchange_a,
                        account_id: :main,
                        product_symbol: :btc_usd,
                        side: :buy,
                        type: :limit,
                        time_in_force: :gtc,
                        status: :canceling,
                        error_reason: nil
                      } = event_1}

      assert event_1.price == Decimal.new("100.1")
      assert event_1.size == Decimal.new("0.1")

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{
                        client_id: ^client_id,
                        venue_id: :test_exchange_a,
                        account_id: :main,
                        product_symbol: :btc_usd,
                        side: :buy,
                        type: :limit,
                        time_in_force: :gtc,
                        status: :canceled,
                        error_reason: nil
                      } = event_2}

      assert event_2.price == Decimal.new("100.1")
      assert event_2.size == Decimal.new("0.1")
    end
  end

  test "returns an error tuple and broadcasts and event when the status is not pending" do
    Tai.Events.firehose_subscribe()

    order =
      OrderPipeline.enqueue(%Tai.Trading.Orders.BuyLimit{
        venue_id: :test_exchange_a,
        account_id: :main,
        product_symbol: :btc_usd_expired,
        price: 100.1,
        qty: 0.1,
        time_in_force: :gtc
      })

    assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :error}}

    assert OrderPipeline.cancel(order) == {:error, :order_status_must_be_pending}

    client_id = order.client_id

    assert_receive {Tai.Event,
                    %Tai.Events.CancelOrderInvalidStatus{
                      client_id: ^client_id,
                      was: :error,
                      required: :pending
                    }}
  end
end
