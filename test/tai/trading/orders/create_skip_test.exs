defmodule Tai.Trading.Orders.CreateSkipTest do
  use ExUnit.Case, async: false

  import Tai.TestSupport.Helpers
  alias Tai.TestSupport.Mocks

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai)
    end)

    start_supervised!(Mocks.Server)
    {:ok, _} = Application.ensure_all_started(:tai)
    Tai.Settings.disable_send_orders!()

    :ok
  end

  test "broadcasts events when the status changes" do
    Tai.Events.firehose_subscribe()

    submission =
      Support.OrderSubmissions.build(Tai.Trading.OrderSubmissions.BuyLimitGtc, %{
        qty: Decimal.new(10)
      })

    {:ok, _} = Tai.Trading.Orders.create(submission)

    assert_receive {Tai.Event, %Tai.Events.OrderUpdated{side: :buy, status: :enqueued}}

    assert_receive {Tai.Event,
                    %Tai.Events.OrderUpdated{side: :buy, status: :skip} = skipped_event}

    assert skipped_event.qty == Decimal.new(10)
    assert skipped_event.leaves_qty == Decimal.new(0)
    assert skipped_event.cumulative_qty == Decimal.new(0)
  end

  test "fires the callback when the status changes" do
    submission =
      Support.OrderSubmissions.build(Tai.Trading.OrderSubmissions.SellLimitGtc, %{
        qty: Decimal.new(1),
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
      %Tai.Trading.Order{side: :sell, status: :skip} = skipped_order
    }

    assert skipped_order.leaves_qty == Decimal.new(0)
    assert skipped_order.cumulative_qty == Decimal.new(0)
  end
end
