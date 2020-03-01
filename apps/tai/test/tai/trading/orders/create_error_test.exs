defmodule Tai.Trading.Orders.CreateErrorTest do
  use ExUnit.Case, async: false
  alias Tai.TestSupport.Mocks
  alias Tai.Trading.{Order, Orders, OrderSubmissions}

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai_events)
      :ok = Application.stop(:tai)
    end)

    start_supervised!(Mocks.Server)
    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  [{:buy, OrderSubmissions.BuyLimitGtc}, {:sell, OrderSubmissions.SellLimitGtc}]
  |> Enum.each(fn {side, submission_type} ->
    @submission_type submission_type

    test "#{side} records the error reason" do
      submission = Support.OrderSubmissions.build_with_callback(@submission_type)
      {:ok, _} = Orders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %Order{status: :enqueued}
      }

      assert_receive {
        :callback_fired,
        %Order{status: :enqueued},
        %Order{status: :create_error} = error_order
      }

      assert error_order.error_reason == :mock_not_found
      assert %DateTime{} = error_order.last_received_at
    end

    test "#{side} rescues adapter errors" do
      submission = Support.OrderSubmissions.build_with_callback(@submission_type)
      Mocks.Responses.Orders.Error.create_raise(submission, "Venue Adapter Create Raised Error")
      {:ok, _} = Orders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %Order{status: :enqueued}
      }

      assert_receive {
        :callback_fired,
        %Order{status: :enqueued},
        %Order{status: :create_error} = error_order
      }

      assert %DateTime{} = error_order.last_received_at
      assert {:unhandled, {error, [stack_1 | _]}} = error_order.error_reason
      assert error == %RuntimeError{message: "Venue Adapter Create Raised Error"}
      assert {Tai.VenueAdapters.Mock, _, _, [file: _, line: _]} = stack_1
    end
  end)
end
