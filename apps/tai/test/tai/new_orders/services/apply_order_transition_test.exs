defmodule Tai.NewOrders.Services.ApplyOrderTransitionTest do
  use Tai.TestSupport.DataCase, async: false
  import Mock
  alias Tai.NewOrders

  test "updates the order with the transition attributes, saves the transition and executes the callback" do
    {:ok, enqueued_order} = create_order(%{status: :enqueued})

    with_mock NewOrders.Services.ExecuteOrderCallback, call: fn _previous, _current, _transition -> :ok end do
      assert {:ok, updated_order} = NewOrders.Services.ApplyOrderTransition.call(enqueued_order.client_id, %{__type__: :skip})
      assert %NewOrders.Order{} = updated_order
      assert updated_order.status == :skipped

      assert_called NewOrders.Services.ExecuteOrderCallback.call(:_, :_, :_)
    end
  end

  test "returns an error when the order doesn't exist" do
    with_mock NewOrders.Services.ExecuteOrderCallback, call: fn _previous, _current, _transition -> :ok end do
      assert {:error, reason} = NewOrders.Services.ApplyOrderTransition.call(Ecto.UUID.generate(), %{__type__: :skip})
      assert reason == :order_not_found

      assert_not_called NewOrders.Services.ExecuteOrderCallback.call(:_, :_, :_)
    end
  end

  test "returns an error and records a failed order transition when the order status is not supported by the transition" do
    {:ok, enqueued_order} = create_order(%{status: :canceled})

    with_mock NewOrders.Services.ExecuteOrderCallback, call: fn _previous, _current, _transition -> :ok end do
      assert {:error, reason} = NewOrders.Services.ApplyOrderTransition.call(enqueued_order.client_id, %{__type__: :skip})
      assert reason == {:invalid_status, :canceled}

      assert_not_called NewOrders.Services.ExecuteOrderCallback.call(:_, :_, :_)

      failed_order_transitions = NewOrders.OrderRepo.all(NewOrders.FailedOrderTransition)
      assert length(failed_order_transitions) == 1
      failed_order_transition = Enum.at(failed_order_transitions, 0)
      assert failed_order_transition.error == reason
      assert failed_order_transition.type == "skip"
    end
  end

  test "records a failed order transition when the transition attributes are invalid" do
    {:ok, enqueued_order} = create_order(%{status: :enqueued})

    with_mock NewOrders.Services.ExecuteOrderCallback, call: fn _previous, _current, _transition -> :ok end do
      assert {:error, reason} = NewOrders.Services.ApplyOrderTransition.call(enqueued_order.client_id, %{__type__: :accept_create})
      assert reason == %{transition: %{venue_order_id: ["can't be blank"], last_received_at: ["can't be blank"]}}

      assert_not_called NewOrders.Services.ExecuteOrderCallback.call(:_, :_, :_)

      failed_order_transitions = NewOrders.OrderRepo.all(NewOrders.FailedOrderTransition)
      assert length(failed_order_transitions) == 1
      failed_order_transition = Enum.at(failed_order_transitions, 0)
      assert failed_order_transition.error == reason
      assert failed_order_transition.type == "accept_create"
    end
  end

  test "records a failed order transition when the transition type is invalid" do
    {:ok, enqueued_order} = create_order(%{status: :enqueued})

    with_mock NewOrders.Services.ExecuteOrderCallback, call: fn _previous, _current, _transition -> :ok end do
      assert {:error, reason} = NewOrders.Services.ApplyOrderTransition.call(enqueued_order.client_id, %{__type__: :not_supported})
      assert reason == %RuntimeError{message: "could not infer polymorphic embed from data %{__type__: :not_supported}"}

      assert_not_called NewOrders.Services.ExecuteOrderCallback.call(:_, :_, :_)

      failed_order_transitions = NewOrders.OrderRepo.all(NewOrders.FailedOrderTransition)
      assert length(failed_order_transitions) == 1
      failed_order_transition = Enum.at(failed_order_transitions, 0)
      assert failed_order_transition.error == reason
      assert failed_order_transition.type == "not_supported"
    end
  end

  test "records a failed order transition when there is no transition type" do
    {:ok, enqueued_order} = create_order(%{status: :enqueued})

    with_mock NewOrders.Services.ExecuteOrderCallback, call: fn _previous, _current, _transition -> :ok end do
      assert {:error, reason} = NewOrders.Services.ApplyOrderTransition.call(enqueued_order.client_id, %{})
      assert reason == %RuntimeError{message: "could not infer polymorphic embed from data %{}"}

      assert_not_called NewOrders.Services.ExecuteOrderCallback.call(:_, :_, :_)

      failed_order_transitions = NewOrders.OrderRepo.all(NewOrders.FailedOrderTransition)
      assert length(failed_order_transitions) == 1
      failed_order_transition = Enum.at(failed_order_transitions, 0)
      assert failed_order_transition.error == reason
      assert failed_order_transition.type == nil
    end
  end
end
