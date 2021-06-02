defmodule Tai.NewOrders.CancelTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.NewOrders

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"
  @venue :venue_a
  @credential :main
  @credentials Map.put(%{}, @credential, %{})

  setup do
    mock_venue(id: @venue, credentials: @credentials, adapter: Tai.VenueAdapters.Mock)

    :ok
  end

  [
    :buy,
    :sell
  ]
  |> Enum.each(fn side ->
    @side side

    test "#{side} cancels the order on the venue and locally records that it was accepted" do
      {:ok, open_order} = create_open_order(%{side: @side})
      Mocks.Responses.NewOrders.GoodTillCancel.cancel_accepted(@venue_order_id)

      assert {:ok, %NewOrders.Order{status: :pending_cancel}} = NewOrders.cancel(open_order)

      assert_receive {
        :callback_fired,
        %NewOrders.Order{status: :open},
        %NewOrders.Order{status: :pending_cancel},
        _
      }

      assert_receive {
        :callback_fired,
        %NewOrders.Order{status: :pending_cancel},
        %NewOrders.Order{} = updated_order,
        transition
      }

      assert %NewOrders.Transitions.AcceptCancel{} = transition

      assert updated_order.status == :cancel_accepted
      assert updated_order.last_received_at != open_order.last_received_at
    end

    test "#{side} records the error when it can't be canceled on the venue" do
      {:ok, open_order} = create_open_order(%{side: @side})

      assert {:ok, _} = NewOrders.cancel(open_order)

      assert_receive {
        :callback_fired,
        %NewOrders.Order{status: :pending_cancel},
        %NewOrders.Order{} = updated_order,
        transition
      }

      assert %NewOrders.Transitions.VenueCancelError{} = transition
      assert transition.reason == :mock_not_found

      assert updated_order.status == :open
    end

    test "#{side} records a failed transition and doesn't execute the callback when the adapter returns an invalid response" do
      {:ok, open_order} = create_open_order(%{side: @side})
      Mocks.Responses.NewOrders.GoodTillCancel.cancel_accepted(@venue_order_id, %{venue_timestamp: "invalid date"})

      assert {:ok, _} = NewOrders.cancel(open_order)

      assert_receive {
        :callback_fired,
        %NewOrders.Order{status: :open},
        %NewOrders.Order{status: :pending_cancel},
        _
      }

      refute_receive {
        :callback_fired,
        %NewOrders.Order{status: :pending_cancel},
        %NewOrders.Order{},
        _transition
      }

      failed_order_transitions = NewOrders.OrderRepo.all(NewOrders.FailedOrderTransition)
      assert length(failed_order_transitions) == 1
      failed_order_transition = Enum.at(failed_order_transitions, 0)
      assert failed_order_transition.type == "accept_cancel"
    end

    test "#{side} records an error when raised by the adapter" do
      {:ok, open_order} = create_open_order(%{side: @side})

      Mocks.Responses.NewOrders.Error.cancel_raise(
        @venue_order_id,
        "Venue Adapter Cancel Raised Error"
      )

      assert {:ok, _} = NewOrders.cancel(open_order)

      assert_receive {
        :callback_fired,
        %NewOrders.Order{status: :pending_cancel},
        %NewOrders.Order{} = updated_order,
        transition
      }

      assert %NewOrders.Transitions.RescueCancelError{} = transition
      assert transition.error == %RuntimeError{message: "Venue Adapter Cancel Raised Error"}
      assert [stack_1 | _] = transition.stacktrace
      assert {Tai.VenueAdapters.Mock, _, _, [file: _, line: _]} = stack_1

      assert updated_order.status == :open
    end
  end)

  defp create_open_order(attrs) do
    %{
      venue_order_id: @venue_order_id,
      status: :open,
      time_in_force: :gtc,
      type: :limit,
      venue: @venue |> Atom.to_string(),
      credential: @credential |> Atom.to_string(),
    }
    |> Map.merge(attrs)
    |> create_order_with_callback()
  end
end
