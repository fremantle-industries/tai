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
  @submission_types [
    {:buy, Tai.Trading.OrderSubmissions.BuyLimitGtc},
    {:sell, Tai.Trading.OrderSubmissions.SellLimitGtc}
  ]

  @submission_types
  |> Enum.each(fn {side, submission_type} ->
    @side side
    @submission_type submission_type

    test "#{side} enqueues the order" do
      submission = Support.OrderSubmissions.build(@submission_type)
      Mocks.Responses.Orders.GoodTillCancel.open(@venue_order_id, submission)

      assert {:ok, %Tai.Trading.Order{} = order} = Tai.Trading.Orders.create(submission)
      assert order.venue_order_id == nil
      assert order.client_id != nil
      assert order.exchange_id == submission.venue_id
      assert order.account_id == submission.account_id
      assert order.symbol == submission.product_symbol
      assert order.side == @side
      assert order.status == :enqueued
      assert order.price == submission.price
      assert order.qty == submission.qty
      assert order.time_in_force == :gtc
      assert order.last_received_at == nil
      assert order.last_venue_timestamp == nil
    end

    test "#{side} updates the venue_order_id, timestamps, leaves_qty, cumulative_qty & avg price" do
      original_price = Decimal.new(2000)
      original_qty = Decimal.new(10)

      submission =
        Support.OrderSubmissions.build(@submission_type, %{
          price: original_price,
          qty: original_qty,
          order_updated_callback: fire_order_callback(self())
        })

      cumulative_qty = Decimal.new(4)
      avg_price = Decimal.new(2000)

      Mocks.Responses.Orders.GoodTillCancel.open(@venue_order_id, submission, %{
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
        %Tai.Trading.Order{status: :enqueued} = enqueued_order,
        %Tai.Trading.Order{status: :open} = open_order
      }

      assert enqueued_order.venue_order_id == nil
      assert enqueued_order.side == @side

      assert open_order.venue_order_id == @venue_order_id
      assert open_order.side == @side
      assert open_order.avg_price == original_price
      assert open_order.leaves_qty == Decimal.new(6)
      assert open_order.cumulative_qty == cumulative_qty
      assert open_order.qty == original_qty
      assert %DateTime{} = open_order.last_received_at
      assert %DateTime{} = open_order.last_venue_timestamp
    end
  end)
end
