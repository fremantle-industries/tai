defmodule Tai.Orders.CreateSkipTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.Orders.{Order, Submissions}

  setup do
    Tai.Settings.disable_send_orders!()

    :ok
  end

  [
    {:buy, Submissions.BuyLimitGtc},
    {:sell, Submissions.SellLimitGtc}
  ]
  |> Enum.each(fn {side, submission_type} ->
    @submission_type submission_type

    test "#{side} updates the leaves qty" do
      submission = Support.Orders.build_submission_with_callback(@submission_type)

      {:ok, _} = Tai.Orders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %Order{status: :enqueued}
      }

      assert_receive {
        :callback_fired,
        %Order{status: :enqueued},
        %Order{status: :skip} = skipped_order
      }

      assert skipped_order.leaves_qty == Decimal.new(0)
    end
  end)
end
