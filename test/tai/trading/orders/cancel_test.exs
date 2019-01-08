defmodule Tai.Trading.Orders.CancelTest do
  use ExUnit.Case, async: false

  import Tai.TestSupport.Helpers
  alias Tai.Trading.Orders
  alias Tai.TestSupport.Mocks

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    start_supervised!(Mocks.Server)
    {:ok, _} = Application.ensure_all_started(:tai)

    :ok
  end

  describe "success" do
    @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"

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

      submission =
        Support.OrderSubmissions.build(Tai.Trading.OrderSubmissions.BuyLimitGtc, %{
          order_updated_callback: fire_order_callback(self())
        })

      {:ok, order} = Orders.create(submission)

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :enqueued},
        %Tai.Trading.Order{status: :open}
      }

      {:ok, %{order: order}}
    end

    test "executes the callback when the status is updated",
         %{order: order} do
      Mocks.Responses.Orders.GoodTillCancel.canceled(@venue_order_id)

      assert {:ok, %Tai.Trading.Order{status: :canceling}} = Orders.cancel(order)

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :open},
        %Tai.Trading.Order{status: :canceling}
      }

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :canceling},
        %Tai.Trading.Order{status: :canceled}
      }
    end

    test "broadcasts events when the status changes",
         %{order: order} do
      Tai.Events.firehose_subscribe()

      Mocks.Responses.Orders.GoodTillCancel.canceled(@venue_order_id)

      assert {:ok, %Tai.Trading.Order{status: :canceling}} = Orders.cancel(order)

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
      assert event_1.qty == Decimal.new("0.1")

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
      assert event_2.qty == Decimal.new("0.1")
    end
  end

  test "returns an error tuple and broadcasts an event when the status is not open" do
    Tai.Events.firehose_subscribe()
    submission = Support.OrderSubmissions.build(Tai.Trading.OrderSubmissions.BuyLimitGtc)
    {:ok, order} = Orders.create(submission)

    assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :error}}

    assert Orders.cancel(order) == {:error, :order_status_must_be_open}

    client_id = order.client_id

    assert_receive {Tai.Event,
                    %Tai.Events.CancelOrderInvalidStatus{
                      client_id: ^client_id,
                      was: :error,
                      required: :open
                    }}
  end
end
