defmodule Tai.Trading.Orders.CancelTest do
  use ExUnit.Case, async: false
  alias Tai.Trading.{Order, Orders, OrderSubmissions}
  alias Tai.TestSupport.Mocks

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    start_supervised!(Mocks.Server)
    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"
  @sides [
    {:buy, OrderSubmissions.BuyLimitGtc},
    {:sell, OrderSubmissions.SellLimitGtc}
  ]

  @sides
  |> Enum.each(fn {side, submission_type} ->
    @submission_type submission_type

    test "#{side} cancels the order on the venue" do
      submission = Support.OrderSubmissions.build_with_callback(@submission_type)
      Mocks.Responses.Orders.GoodTillCancel.open(@venue_order_id, submission)

      {:ok, order} = Orders.create(submission)
      assert_receive {:callback_fired, %Order{status: :enqueued}, %Order{status: :open}}

      Mocks.Responses.Orders.GoodTillCancel.canceled(@venue_order_id)
      assert {:ok, %Order{status: :pending_cancel}} = Orders.cancel(order)
      assert_receive {:callback_fired, %Order{status: :open}, %Order{status: :pending_cancel}}
      assert_receive {:callback_fired, %Order{status: :pending_cancel}, %Order{status: :canceled}}
    end
  end)
end
