defmodule Tai.Trading.Orders.CreateFilledTest do
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
    {:buy, Tai.Trading.OrderSubmissions.BuyLimitFok},
    {:sell, Tai.Trading.OrderSubmissions.SellLimitFok}
  ]

  @submission_types
  |> Enum.each(fn {side, submission_type} ->
    @side side
    @submission_type submission_type

    test "#{side} updates the venue_order_id, venue_created_at, leaves_qty, cumulative qty & avg price" do
      original_qty = Decimal.new(10)

      submission =
        Support.OrderSubmissions.build(@submission_type, %{
          qty: original_qty,
          order_updated_callback: fire_order_callback(self())
        })

      Mocks.Responses.Orders.FillOrKill.filled(@venue_order_id, submission)

      {:ok, _} = Tai.Trading.Orders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %Tai.Trading.Order{status: :enqueued}
      }

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{status: :enqueued},
        %Tai.Trading.Order{status: :filled} = filled_order
      }

      assert filled_order.venue_order_id == @venue_order_id
      assert filled_order.side == @side
      assert %DateTime{} = filled_order.venue_created_at
      assert filled_order.avg_price != Decimal.new(0)
      assert filled_order.leaves_qty == Decimal.new(0)
      assert filled_order.cumulative_qty == original_qty
      assert filled_order.qty == original_qty
    end
  end)
end
