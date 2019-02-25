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
  @submission_types [
    {:buy, Tai.Trading.OrderSubmissions.BuyLimitIoc},
    {:sell, Tai.Trading.OrderSubmissions.SellLimitIoc}
  ]

  @submission_types
  |> Enum.each(fn {side, submission_type} ->
    @side side
    @submission_type submission_type

    test "#{side} updates the venue_order_id, last_venue_timestamp, leaves_qty, cumulative qty & avg price" do
      original_qty = Decimal.new(10)
      cumulative_qty = Decimal.new(3)
      avg_price = Decimal.new("1000.5")

      submission =
        Support.OrderSubmissions.build(@submission_type, %{
          qty: original_qty,
          order_updated_callback: fire_order_callback(self())
        })

      Mocks.Responses.Orders.ImmediateOrCancel.expired(@venue_order_id, submission, %{
        cumulative_qty: cumulative_qty,
        avg_price: avg_price
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
        %Tai.Trading.Order{status: :expired} = expired_order
      }

      assert expired_order.venue_order_id == @venue_order_id
      assert expired_order.side == @side
      assert expired_order.avg_price == avg_price
      assert expired_order.leaves_qty == Decimal.new(0)
      assert expired_order.cumulative_qty == cumulative_qty
      assert expired_order.qty == original_qty
      assert %DateTime{} = expired_order.last_venue_timestamp
    end
  end)
end
