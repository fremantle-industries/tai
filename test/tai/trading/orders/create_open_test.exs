defmodule Tai.Trading.Orders.CreateOpenTest do
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

  test "enqueues the order" do
    submission = Support.OrderSubmissions.build(Tai.Trading.OrderSubmissions.BuyLimitGtc)
    Mocks.Responses.Orders.GoodTillCancel.unfilled(@venue_order_id, submission)

    assert {:ok, %Tai.Trading.Order{} = order} = Tai.Trading.Orders.create(submission)
    assert order.venue_order_id == nil
    assert order.client_id != nil
    assert order.exchange_id == submission.venue_id
    assert order.account_id == submission.account_id
    assert order.symbol == submission.product_symbol
    assert order.side == :buy
    assert order.status == :enqueued
    assert order.price == submission.price
    assert order.qty == submission.qty
    assert order.time_in_force == :gtc
    assert order.venue_created_at == nil
  end

  test "broadcasts events when the status changes" do
    Tai.Events.firehose_subscribe()
    submission = Support.OrderSubmissions.build(Tai.Trading.OrderSubmissions.BuyLimitGtc)
    Mocks.Responses.Orders.GoodTillCancel.unfilled(@venue_order_id, submission)

    assert {:ok, _} = Tai.Trading.Orders.create(submission)

    assert_receive {Tai.Event,
                    %Tai.Events.OrderUpdated{side: :buy, status: :enqueued} = enqueued_order}

    assert_receive {Tai.Event,
                    %Tai.Events.OrderUpdated{side: :buy, status: :open} = open_order_event}

    assert enqueued_order.venue_order_id == nil
    assert open_order_event.venue_order_id == @venue_order_id
    assert %DateTime{} = open_order_event.venue_created_at
  end

  test "fires the callback when the status changes" do
    submission =
      Support.OrderSubmissions.build(Tai.Trading.OrderSubmissions.SellLimitGtc, %{
        order_updated_callback: fire_order_callback(self())
      })

    Mocks.Responses.Orders.GoodTillCancel.unfilled(@venue_order_id, submission)

    {:ok, _} = Tai.Trading.Orders.create(submission)

    assert_receive {
      :callback_fired,
      nil,
      %Tai.Trading.Order{side: :sell, status: :enqueued}
    }

    assert_receive {
      :callback_fired,
      %Tai.Trading.Order{side: :sell, status: :enqueued} = enqueued_order,
      %Tai.Trading.Order{side: :sell, status: :open} = open_order
    }

    assert enqueued_order.venue_order_id == nil
    assert open_order.venue_order_id == @venue_order_id
    assert %DateTime{} = open_order.venue_created_at
  end
end
