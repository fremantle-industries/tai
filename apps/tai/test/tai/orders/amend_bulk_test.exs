defmodule Tai.Orders.AmendBulkTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.Orders

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"
  # @pending_venue_order_id "df8e6bd0-a40a-42fb-8fea-pending"
  @venue :venue_a
  @credential :main
  @credentials Map.put(%{}, @credential, %{})
  @original_price Decimal.new(100)
  @original_qty Decimal.new(1)
  @amend_price Decimal.new("105.5")
  @amend_qty Decimal.new(10)

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

    test "#{side} changes the price & qty of each order on the venue and locally records that they were accepte" do
      {:ok, open_order} = create_open_order(%{side: @side})

      Mocks.Responses.Orders.GoodTillCancel.amend_bulk_accepted([
        {open_order, %{price: @amend_price, qty: @amend_qty}}
      ])

      amend_set = [
        {open_order, %{price: @amend_price, qty: @amend_qty}}
        # {pending_order, %{price: @amend_price, qty: @amend_qty}}
      ]

      assert [
               {:ok, returned_order}
               # {:error, amend_error}
             ] = Orders.amend_bulk(amend_set)

      assert returned_order.status == :pending_amend
      assert returned_order.price == @original_price
      assert returned_order.leaves_qty == @original_qty
      assert returned_order.qty == @original_qty

      assert_receive {
        :callback_fired,
        %Tai.Orders.Order{status: :open},
        %Tai.Orders.Order{status: :pending_amend},
        _
      }

      assert_receive {
        :callback_fired,
        %Tai.Orders.Order{status: :pending_amend},
        %Tai.Orders.Order{} = updated_order,
        transition
      }

      assert %Orders.Transitions.AcceptAmend{} = transition

      assert updated_order.status == :amend_accepted
      assert updated_order.last_received_at != open_order.last_received_at
    end

    test "#{side} records the error when it can't be canceled on the venue" do
      {:ok, open_order} = create_open_order(%{side: @side})

      amend_set = [{open_order, %{price: @amend_price, qty: @amend_qty}}]
      assert [{:ok, %Orders.Order{status: :pending_amend}}] = Orders.amend_bulk(amend_set)

      assert_receive {
        :callback_fired,
        %Tai.Orders.Order{status: :pending_amend},
        %Tai.Orders.Order{} = updated_order,
        transition
      }

      assert %Orders.Transitions.VenueAmendError{} = transition
      assert transition.reason == :mock_not_found

      assert updated_order.status == :open
    end

    test "#{side} records a failed transition and doesn't execute the callback when the adapter returns an invalid response" do
      {:ok, open_order} = create_open_order(%{side: @side})

      Mocks.Responses.Orders.GoodTillCancel.amend_bulk_accepted(
        [{open_order, %{price: @amend_price, qty: @amend_qty}}],
        [%{venue_timestamp: "invalid date"}]
      )

      assert [{:ok, _}] =
               Orders.amend_bulk([{open_order, %{price: @amend_price, qty: @amend_qty}}])

      assert_receive {
        :callback_fired,
        %Tai.Orders.Order{status: :open},
        %Tai.Orders.Order{status: :pending_amend},
        _
      }

      refute_receive {
        :callback_fired,
        %Tai.Orders.Order{status: :pending_amend},
        %Tai.Orders.Order{},
        _transition
      }

      failed_order_transitions = Orders.OrderRepo.all(Orders.FailedOrderTransition)
      assert length(failed_order_transitions) == 1
      failed_order_transition = Enum.at(failed_order_transitions, 0)
      assert failed_order_transition.type == "accept_amend"
    end

    test "#{side} records an error when raised by the adapter" do
      {:ok, open_order} = create_open_order(%{side: @side})

      Mocks.Responses.Orders.Error.amend_bulk_raise(
        [%{venue_order_id: @venue_order_id, price: @amend_price, qty: @amend_qty}],
        "Venue Adapter Amend Raised Error"
      )

      assert [{:ok, _}] =
               Orders.amend_bulk([{open_order, %{price: @amend_price, qty: @amend_qty}}])

      assert_receive {
        :callback_fired,
        %Tai.Orders.Order{status: :pending_amend},
        %Tai.Orders.Order{} = updated_order,
        transition
      }

      assert %Orders.Transitions.RescueAmendError{} = transition
      assert transition.error == %RuntimeError{message: "Venue Adapter Amend Raised Error"}
      assert [stack_1 | _] = transition.stacktrace
      assert {Tai.VenueAdapters.Mock, _, _, [file: _, line: _]} = stack_1

      assert updated_order.status == :open
    end

    test "#{side} returns an error and records a failed transition for orders with an invalid status for pend amend" do
      {:ok, filled_order} = create_filled_order(%{side: @side})

      assert [{:error, reason}] =
               Orders.amend_bulk([{filled_order, %{price: @amend_price, qty: @amend_qty}}])

      assert {:invalid_status, status_was, transition} = reason
      assert status_was == :filled
      assert %Orders.Transitions.PendAmend{} = transition

      failed_order_transitions = Orders.OrderRepo.all(Orders.FailedOrderTransition)
      assert length(failed_order_transitions) == 1
      failed_order_transition = Enum.at(failed_order_transitions, 0)
      assert failed_order_transition.type == "pend_amend"
    end
  end)

  defp create_test_order(attrs) do
    %{
      venue_order_id: @venue_order_id,
      venue: @venue |> Atom.to_string(),
      credential: @credential |> Atom.to_string(),
      price: @original_price,
      qty: @original_qty,
      leaves_qty: @original_qty,
      cumulative_qty: Decimal.new(0),
      time_in_force: :gtc,
      type: :limit
    }
    |> Map.merge(attrs)
    |> create_order_with_callback()
  end

  defp create_open_order(attrs) do
    %{status: :open}
    |> Map.merge(attrs)
    |> create_test_order()
  end

  defp create_filled_order(attrs) do
    %{status: :filled}
    |> Map.merge(attrs)
    |> create_test_order()
  end
end
