defmodule Tai.Trading.Orders.CreateErrorTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Helpers
  alias Tai.TestSupport.Mocks

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai)
    end)

    start_supervised!(Mocks.Server)
    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  @submission_types [
    {:buy, Tai.Trading.OrderSubmissions.BuyLimitGtc},
    {:sell, Tai.Trading.OrderSubmissions.SellLimitGtc}
  ]

  @submission_types
  |> Enum.each(fn {side, submission_type} ->
    @side side
    @submission_type submission_type

    test "#{side} updates the error reason and sets leaves qty to 0" do
      submission =
        Support.OrderSubmissions.build(@submission_type, %{
          qty: Decimal.new(10),
          order_updated_callback: fire_order_callback(self())
        })

      {:ok, _} = Tai.Trading.Orders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %Tai.Trading.Order{status: :enqueued}
      }

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :enqueued},
        %Tai.Trading.Order{status: :create_error} = error_order
      }

      assert error_order.side == @side
      assert error_order.error_reason == :mock_not_found
      assert error_order.leaves_qty == Decimal.new(0)
      assert error_order.qty == Decimal.new(10)
      assert error_order.cumulative_qty == Decimal.new(0)
      assert %DateTime{} = error_order.last_received_at
    end

    test "#{side} assigns the error reason in the updated event" do
      Tai.Events.firehose_subscribe()

      submission =
        Support.OrderSubmissions.build(@submission_type, %{
          qty: Decimal.new(10)
        })

      {:ok, _} = Tai.Trading.Orders.create(submission)

      assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :enqueued}, _}
      assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :create_error} = error_event, _}

      assert error_event.side == @side
      assert error_event.error_reason == :mock_not_found
    end

    test "#{side} rescues adapter errors" do
      submission =
        Support.OrderSubmissions.build(@submission_type, %{
          qty: Decimal.new(10),
          order_updated_callback: fire_order_callback(self())
        })

      Mocks.Responses.Orders.Error.create_raise(submission, "Venue Adapter Create Raised Error")

      {:ok, _} = Tai.Trading.Orders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %Tai.Trading.Order{status: :enqueued}
      }

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :enqueued},
        %Tai.Trading.Order{status: :create_error} = error_order
      }

      assert error_order.side == @side
      assert %DateTime{} = error_order.last_received_at
      assert {:unhandled, {error, [stack_1 | _]}} = error_order.error_reason
      assert error == %RuntimeError{message: "Venue Adapter Create Raised Error"}
      assert {Tai.VenueAdapters.Mock, _, _, [file: _, line: _]} = stack_1
    end
  end)
end
