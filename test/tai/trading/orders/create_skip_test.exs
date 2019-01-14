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

  @submission_types [
    {:buy, Tai.Trading.OrderSubmissions.BuyLimitGtc},
    {:sell, Tai.Trading.OrderSubmissions.SellLimitGtc}
  ]

  @submission_types
  |> Enum.each(fn {side, submission_type} ->
    @side side
    @submission_type submission_type

    test "#{side} updates the leaves qty" do
      submission =
        Support.OrderSubmissions.build(@submission_type, %{
          qty: Decimal.new(1),
          order_updated_callback: fire_order_callback(self())
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
        %Tai.Trading.Order{status: :skip} = skipped_order
      }

      assert skipped_order.side == @side
      assert skipped_order.leaves_qty == Decimal.new(0)
    end
  end)
end
