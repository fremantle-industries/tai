defmodule Tai.NewOrders.Services.EnqueueOrderTest do
  use Tai.TestSupport.DataCase, async: false
  import Mock
  alias Tai.NewOrders

  test "creates an order and executes the callback" do
    submission = build_submission(NewOrders.Submissions.BuyLimitGtc)

    with_mock NewOrders.Services.ExecuteOrderCallback, call: fn _previous, _current, _transition -> :ok end do
      assert {:ok, enqueued_order} = NewOrders.Services.EnqueueOrder.call(submission)
      assert %NewOrders.Order{} = enqueued_order
      assert enqueued_order.status == :enqueued

      assert_called NewOrders.Services.ExecuteOrderCallback.call(:_, :_, nil)
    end
  end
end
