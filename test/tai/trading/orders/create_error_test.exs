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

  test "assigns the error reason and broadcasts events when the status changes" do
    Tai.Events.firehose_subscribe()

    submission =
      Support.OrderSubmissions.build(Tai.Trading.OrderSubmissions.BuyLimitFok, %{
        qty: Decimal.new(10)
      })

    {:ok, _} = Tai.Trading.Orders.create(submission)

    assert_receive {Tai.Event, %Tai.Events.OrderUpdated{side: :buy, status: :enqueued}}

    assert_receive {Tai.Event,
                    %Tai.Events.OrderUpdated{
                      side: :buy,
                      status: :error,
                      error_reason: :mock_not_found
                    } = error_event}

    assert error_event.leaves_qty == Decimal.new(0)
    assert error_event.qty == Decimal.new(10)
    assert error_event.cumulative_qty == Decimal.new(0)
  end

  test "fires the callback when the status changes" do
    submission =
      Support.OrderSubmissions.build(Tai.Trading.OrderSubmissions.SellLimitFok, %{
        qty: Decimal.new(10),
        order_updated_callback: fire_order_callback(self())
      })

    {:ok, _} = Tai.Trading.Orders.create(submission)

    assert_receive {
      :callback_fired,
      nil,
      %Tai.Trading.Order{side: :sell, status: :enqueued}
    }

    assert_receive {
      :callback_fired,
      %Tai.Trading.Order{side: :sell, status: :enqueued},
      %Tai.Trading.Order{side: :sell, status: :error, error_reason: :mock_not_found} = error_order
    }

    assert error_order.leaves_qty == Decimal.new(0)
    assert error_order.qty == Decimal.new(10)
    assert error_order.cumulative_qty == Decimal.new(0)
  end
end
