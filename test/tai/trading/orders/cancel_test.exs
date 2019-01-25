defmodule Tai.Trading.Orders.CancelTest do
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

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"
  @submission_types [
    {:buy, Tai.Trading.OrderSubmissions.BuyLimitGtc},
    {:sell, Tai.Trading.OrderSubmissions.SellLimitGtc}
  ]

  @submission_types
  |> Enum.each(fn {side, submission_type} ->
    @submission_type submission_type

    describe "#{side} success" do
      setup do
        submission =
          struct(@submission_type, %{
            venue_id: :test_exchange_a,
            account_id: :main,
            product_symbol: :btc_usd,
            price: Decimal.new("100.1"),
            qty: Decimal.new("0.1"),
            post_only: true,
            order_updated_callback: fire_order_callback(self())
          })

        Mocks.Responses.Orders.GoodTillCancel.open(@venue_order_id, submission)
        {:ok, order} = Tai.Trading.Orders.create(submission)

        assert_receive {
          :callback_fired,
          %Tai.Trading.Order{status: :enqueued},
          %Tai.Trading.Order{status: :open}
        }

        {:ok, %{order: order}}
      end

      test "sets the timestamp & assigns leaves_qty to 0",
           %{order: order} do
        Mocks.Responses.Orders.GoodTillCancel.canceled(@venue_order_id)

        assert {:ok, %Tai.Trading.Order{status: :pending_cancel}} =
                 Tai.Trading.Orders.cancel(order)

        assert_receive {
          :callback_fired,
          %Tai.Trading.Order{status: :open},
          %Tai.Trading.Order{status: :pending_cancel} = pending_cancel_order
        }

        assert_receive {
          :callback_fired,
          %Tai.Trading.Order{status: :pending_cancel},
          %Tai.Trading.Order{status: :canceled} = canceled_order
        }

        assert pending_cancel_order.leaves_qty != Decimal.new(0)
        assert %DateTime{} = pending_cancel_order.updated_at
        assert pending_cancel_order.venue_updated_at == nil

        assert canceled_order.leaves_qty == Decimal.new(0)
        assert %DateTime{} = canceled_order.updated_at
        assert canceled_order.updated_at == pending_cancel_order.updated_at
        assert %DateTime{} = canceled_order.venue_updated_at
      end
    end

    describe "#{side} invalid order status" do
      setup do
        Tai.Events.firehose_subscribe()
        submission = Support.OrderSubmissions.build(@submission_type)
        {:ok, order} = Tai.Trading.Orders.create(submission)
        assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :create_error}}

        {:ok, %{order: order}}
      end

      test "returns an error tuple when the status is not open", %{order: order} do
        assert {:error, reason} = Tai.Trading.Orders.cancel(order)
        assert reason == {:invalid_status, :create_error, :open}
      end

      test "broadcasts an event when the status is not open", %{order: order} do
        Tai.Trading.Orders.cancel(order)

        assert_receive {Tai.Event, %Tai.Events.OrderUpdateInvalidStatus{} = cancel_error_event}

        assert cancel_error_event.client_id == order.client_id
        assert cancel_error_event.action == :pend_cancel
        assert cancel_error_event.was == :create_error
        assert cancel_error_event.required == :open
      end
    end

    describe "#{side} venue error" do
      test "changes the status to :cancel_error" do
        Tai.Events.firehose_subscribe()
        submission = Support.OrderSubmissions.build(@submission_type)
        Mocks.Responses.Orders.GoodTillCancel.open(@venue_order_id, submission)
        {:ok, order} = Tai.Trading.Orders.create(submission)
        assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :open}}

        assert {:ok, _} = Tai.Trading.Orders.cancel(order)

        assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :cancel_error} = error_event}
        assert error_event.error_reason == :mock_not_found
      end
    end
  end)
end
