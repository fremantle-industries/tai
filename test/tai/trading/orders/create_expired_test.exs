defmodule Tai.Trading.Orders.CreateExpiredTest do
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

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"

  test "broadcasts an event with a status of expired" do
    Tai.Events.firehose_subscribe()

    submission =
      Support.OrderSubmissions.build(Tai.Trading.OrderSubmissions.BuyLimitFok, %{
        qty: Decimal.new(10)
      })

    cumulative_qty = Decimal.new(4)
    Mocks.Responses.Orders.FillOrKill.expired(@venue_order_id, submission, cumulative_qty)

    {:ok, _} = Tai.Trading.Orders.create(submission)

    assert_receive {Tai.Event, %Tai.Events.OrderUpdated{side: :buy, status: :enqueued}}

    assert_receive {Tai.Event,
                    %Tai.Events.OrderUpdated{side: :buy, status: :expired} = expired_event}

    assert expired_event.venue_order_id == @venue_order_id
    assert %DateTime{} = expired_event.venue_created_at
    assert expired_event.leaves_qty == Decimal.new(0)
    assert expired_event.cumulative_qty == cumulative_qty
    assert expired_event.qty == Decimal.new(10)
  end

  test "fires the callback when the status changes" do
    submission =
      Support.OrderSubmissions.build(Tai.Trading.OrderSubmissions.SellLimitFok, %{
        qty: Decimal.new(10),
        order_updated_callback: fire_order_callback(self())
      })

    Mocks.Responses.Orders.FillOrKill.expired(@venue_order_id, submission)

    {:ok, _} = Tai.Trading.Orders.create(submission)

    assert_receive {
      :callback_fired,
      nil,
      %Tai.Trading.Order{side: :sell, status: :enqueued}
    }

    assert_receive {
      :callback_fired,
      %Tai.Trading.Order{side: :sell, status: :enqueued},
      %Tai.Trading.Order{side: :sell, status: :expired} = expired_order
    }

    assert expired_order.venue_order_id == @venue_order_id
    assert %DateTime{} = expired_order.venue_created_at
    assert expired_order.leaves_qty == Decimal.new(0)
    assert expired_order.cumulative_qty == Decimal.new(0)
    assert expired_order.qty == Decimal.new(10)
  end
end
