defmodule Tai.Trading.Orders.CreateRejectedTest do
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
  @submission_types [
    {:buy, Tai.Trading.OrderSubmissions.BuyLimitGtc},
    {:sell, Tai.Trading.OrderSubmissions.SellLimitGtc}
  ]

  @submission_types
  |> Enum.each(fn {side, submission_type} ->
    @side side
    @submission_type submission_type

    test "#{side} updates the venue_order_id, timestamps & leaves_qty" do
      submission =
        Support.OrderSubmissions.build(
          @submission_type,
          %{order_updated_callback: fire_order_callback(self())}
        )

      Mocks.Responses.Orders.GoodTillCancel.rejected(@venue_order_id, submission)

      {:ok, _} = Tai.Trading.Orders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %Tai.Trading.Order{status: :enqueued}
      }

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :enqueued},
        %Tai.Trading.Order{status: :rejected} = rejected_order
      }

      assert rejected_order.venue_order_id == @venue_order_id
      assert rejected_order.side == @side
      assert rejected_order.leaves_qty == Decimal.new(0)
      assert %DateTime{} = rejected_order.last_venue_timestamp
    end
  end)
end
