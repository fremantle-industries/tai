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

  test "broadcasts an event with a status of expired" do
    Tai.Events.firehose_subscribe()
    submission = Support.OrderSubmissions.build(Tai.Trading.OrderSubmissions.BuyLimitFok)

    Mocks.Responses.Orders.FillOrKill.expired(submission)

    {:ok, _} = Tai.Trading.Orders.create(submission)

    assert_receive {Tai.Event, %Tai.Events.OrderUpdated{side: :buy, status: :enqueued}}
    assert_receive {Tai.Event, %Tai.Events.OrderUpdated{side: :buy, status: :expired}}
  end

  test "fires the callback when the status changes" do
    submission =
      Support.OrderSubmissions.build(Tai.Trading.OrderSubmissions.SellLimitFok, %{
        order_updated_callback: fire_order_callback(self())
      })

    Mocks.Responses.Orders.FillOrKill.expired(submission)

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

    assert %DateTime{} = expired_order.venue_created_at
  end
end
