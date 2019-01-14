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
        {:ok, order} = Orders.create(submission)

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

        assert {:ok, %Tai.Trading.Order{status: :canceling}} = Orders.cancel(order)

        assert_receive {
          :callback_fired,
          %Tai.Trading.Order{status: :open},
          %Tai.Trading.Order{status: :canceling} = canceling_order
        }

        assert_receive {
          :callback_fired,
          %Tai.Trading.Order{status: :canceling},
          %Tai.Trading.Order{status: :canceled} = canceled_order
        }

        assert canceling_order.leaves_qty != Decimal.new(0)
        assert %DateTime{} = canceling_order.updated_at
        assert canceling_order.venue_updated_at == nil

        assert canceled_order.leaves_qty == Decimal.new(0)
        assert %DateTime{} = canceled_order.updated_at
        assert canceled_order.updated_at == canceling_order.updated_at
        assert %DateTime{} = canceled_order.venue_updated_at
      end
    end
  end)

  describe "failure" do
    test "returns an error tuple when the status is not open" do
      Tai.Events.firehose_subscribe()
      submission = Support.OrderSubmissions.build(Tai.Trading.OrderSubmissions.BuyLimitGtc)
      {:ok, order} = Orders.create(submission)
      assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :error}}

      assert Orders.cancel(order) == {:error, :order_status_must_be_open}
    end

    test "broadcasts an event when the status is not open" do
      Tai.Events.firehose_subscribe()
      submission = Support.OrderSubmissions.build(Tai.Trading.OrderSubmissions.BuyLimitGtc)
      {:ok, order} = Orders.create(submission)
      assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :error}}

      Orders.cancel(order)

      assert_receive {Tai.Event,
                      %Tai.Events.CancelOrderInvalidStatus{
                        was: :error,
                        required: :open
                      } = cancel_error_event}

      assert cancel_error_event.client_id == order.client_id
    end
  end
end
