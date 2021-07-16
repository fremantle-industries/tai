defmodule Tai.Orders.Services.EnqueueOrderTest do
  use Tai.TestSupport.DataCase, async: false
  import Mock

  test "creates an order and executes the callback" do
    submission = build_submission(Tai.Orders.Submissions.BuyLimitGtc)

    with_mock Tai.Orders.Services.ExecuteOrderCallback,
      call: fn _previous, _current, _transition -> :ok end do
      assert {:ok, enqueued_order} = Tai.Orders.Services.EnqueueOrder.call(submission)
      assert %Tai.Orders.Order{} = enqueued_order
      assert enqueued_order.status == :enqueued

      assert_called(Tai.Orders.Services.ExecuteOrderCallback.call(:_, :_, nil))
    end
  end
end
