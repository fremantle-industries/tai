defmodule Tai.Trading.Orders.CancelErrorTest do
  use ExUnit.Case, async: false
  alias Tai.Trading.{Order, Orders, OrderSubmissions}
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

  [{:buy, OrderSubmissions.BuyLimitGtc}, {:sell, OrderSubmissions.SellLimitGtc}]
  |> Enum.each(fn {side, submission_type} ->
    @submission_type submission_type

    describe "#{side} with an invalid status" do
      setup do
        submission = Support.OrderSubmissions.build_with_callback(@submission_type)
        {:ok, order} = Orders.create(submission)
        assert_receive {:callback_fired, _, %Order{status: :create_error}}

        {:ok, %{order: order}}
      end

      test "returns an error", %{order: order} do
        assert {:error, reason} = Orders.cancel(order)

        assert reason ==
                 {:invalid_status, :create_error,
                  [:amend_error, :cancel_error, :open, :partially_filled]}
      end

      test "broadcasts an event", %{order: order} do
        Tai.Events.firehose_subscribe()

        Orders.cancel(order)

        assert_receive {Tai.Event, %Tai.Events.OrderUpdateInvalidStatus{} = cancel_invalid_event,
                        :warn}

        assert cancel_invalid_event.client_id == order.client_id
        assert cancel_invalid_event.action == :pend_cancel
        assert cancel_invalid_event.was == :create_error

        assert cancel_invalid_event.required == [
                 :amend_error,
                 :cancel_error,
                 :open,
                 :partially_filled
               ]
      end
    end

    test "#{side} venue error updates status and records the reason" do
      Tai.Events.firehose_subscribe()
      submission = Support.OrderSubmissions.build_with_callback(@submission_type)
      Mocks.Responses.Orders.GoodTillCancel.open(@venue_order_id, submission)
      {:ok, order} = Tai.Trading.Orders.create(submission)
      assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :open} = open_event, _}

      assert {:ok, _} = Tai.Trading.Orders.cancel(order)

      assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :cancel_error} = error_event, _}
      assert error_event.last_received_at != open_event.last_received_at
      assert error_event.error_reason == :mock_not_found
    end

    test "#{side} adapter error is rescued" do
      submission = Support.OrderSubmissions.build_with_callback(@submission_type)
      Mocks.Responses.Orders.GoodTillCancel.open(@venue_order_id, submission)
      {:ok, order} = Tai.Trading.Orders.create(submission)

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :enqueued},
        %Tai.Trading.Order{status: :open} = open_order
      }

      Mocks.Responses.Orders.Error.cancel_raise(
        @venue_order_id,
        "Venue Adapter Cancel Raised Error"
      )

      assert {:ok, _} = Tai.Trading.Orders.cancel(order)

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :pending_cancel},
        %Tai.Trading.Order{status: :cancel_error} = error_order
      }

      assert {:unhandled, {error, [stack_1 | _]}} = error_order.error_reason
      assert error_order.last_received_at != open_order.last_received_at
      assert error == %RuntimeError{message: "Venue Adapter Cancel Raised Error"}
      assert {Tai.VenueAdapters.Mock, _, _, [file: _, line: _]} = stack_1
    end
  end)
end
