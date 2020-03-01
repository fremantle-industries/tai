defmodule Tai.Trading.Orders.CreateAcceptedTest do
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

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"

  [{:buy, OrderSubmissions.BuyLimitGtc}, {:sell, OrderSubmissions.SellLimitGtc}]
  |> Enum.each(fn {side, submission_type} ->
    @submission_type submission_type

    test "#{side} records the venue order id & timestamp" do
      submission = Support.OrderSubmissions.build_with_callback(@submission_type)
      Mocks.Responses.Orders.GoodTillCancel.create_accepted(@venue_order_id, submission)
      {:ok, _} = Orders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %Order{status: :enqueued}
      }

      assert_receive {
        :callback_fired,
        %Order{status: :enqueued} = enqueued_order,
        %Order{status: :create_accepted} = accepted_order
      }

      assert accepted_order.venue_order_id == @venue_order_id
      assert %DateTime{} = accepted_order.last_received_at
      assert %DateTime{} = accepted_order.last_venue_timestamp
    end
  end)
end
