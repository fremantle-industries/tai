defmodule Tai.Orders.CancelErrorTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Mock
  import Support.Orders
  alias Tai.Orders.OrderSubmissions.SellLimitGtc
  alias Tai.Orders.{Order, Transitions}
  alias Tai.TestSupport.Mocks

  defmodule TestFilledProvider do
    @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"
    @venue :venue_a
    @credential :main

    def update(%Transitions.PendCancel{} = transition) do
      open_order =
        struct(Order,
          client_id: transition.client_id,
          venue_order_id: @venue_order_id,
          venue_id: @venue,
          credential_id: @credential,
          status: :open
        )

      pending_cancel_order =
        struct(Order,
          client_id: open_order.client_id,
          venue_order_id: open_order.venue_order_id,
          venue_id: open_order.venue_id,
          credential_id: open_order.credential_id,
          status: :pending_cancel
        )

      {:ok, {open_order, pending_cancel_order}}
    end

    def update(%Transitions.Cancel{} = transition) do
      {:error, {:invalid_status, :filled, [:cancel_required_a, :cancel_required_b], transition}}
    end
  end

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"
  @venue :venue_a
  @credential :main
  @credentials Map.put(%{}, @credential, %{})
  @submission_attrs %{venue_id: @venue, credential_id: @credential}

  setup do
    setup_orders(&start_supervised!/1)
    mock_venue(id: @venue, credentials: @credentials, adapter: Tai.VenueAdapters.Mock)
    submission = Support.OrderSubmissions.build_with_callback(SellLimitGtc, @submission_attrs)

    {:ok, %{submission: submission}}
  end

  describe "with an invalid pending cancel status" do
    setup(%{submission: submission}) do
      {:ok, order} = Tai.Orders.create(submission)
      assert_receive {:callback_fired, _, %Order{status: :create_error}}

      {:ok, %{order: order}}
    end

    test "returns an error", %{order: order} do
      assert {:error, reason} = Tai.Orders.cancel(order)
      assert {:invalid_status, :create_error, required_status, transition} = reason
      assert required_status == [:amend_error, :cancel_error, :open, :partially_filled]
      assert %Transitions.PendCancel{} = transition
    end

    test "emits an invalid status warning", %{order: order} do
      TaiEvents.firehose_subscribe()

      Tai.Orders.cancel(order)

      assert_receive {
        TaiEvents.Event,
        %Tai.Events.OrderUpdateInvalidStatus{} = pending_cancel_invalid_event,
        :warn
      }

      assert pending_cancel_invalid_event.client_id == order.client_id
      assert pending_cancel_invalid_event.transition == Transitions.PendCancel
      assert pending_cancel_invalid_event.was == :create_error

      assert pending_cancel_invalid_event.required == [
               :amend_error,
               :cancel_error,
               :open,
               :partially_filled
             ]
    end
  end

  test "invalid cancel status emits an event" do
    open_order = struct(Order, client_id: "abc123", venue_order_id: @venue_order_id)
    Mocks.Responses.Orders.GoodTillCancel.canceled(@venue_order_id)
    TaiEvents.firehose_subscribe()

    Tai.Orders.cancel(open_order, TestFilledProvider)

    assert_receive {
      TaiEvents.Event,
      %Tai.Events.OrderUpdateInvalidStatus{} = cancel_invalid_event,
      :warn
    }

    assert cancel_invalid_event.client_id == open_order.client_id
    assert cancel_invalid_event.transition == Transitions.Cancel
    assert cancel_invalid_event.was == :filled

    assert cancel_invalid_event.required == [
             :cancel_required_a,
             :cancel_required_b
           ]
  end

  test "venue error updates status and records the reason", %{submission: submission} do
    TaiEvents.firehose_subscribe()
    Mocks.Responses.Orders.GoodTillCancel.open(@venue_order_id, submission)
    {:ok, order} = Tai.Orders.create(submission)
    assert_receive {TaiEvents.Event, %Tai.Events.OrderUpdated{status: :open} = open_event, _}

    assert {:ok, _} = Tai.Orders.cancel(order)

    assert_receive {TaiEvents.Event,
                    %Tai.Events.OrderUpdated{status: :cancel_error} = error_event, _}

    assert error_event.last_received_at != open_event.last_received_at
    assert error_event.error_reason == :mock_not_found
  end

  test "rescues adapter errors", %{submission: submission} do
    Mocks.Responses.Orders.GoodTillCancel.open(@venue_order_id, submission)
    {:ok, order} = Tai.Orders.create(submission)

    assert_receive {
      :callback_fired,
      %Tai.Orders.Order{status: :enqueued},
      %Tai.Orders.Order{status: :open} = open_order
    }

    Mocks.Responses.Orders.Error.cancel_raise(
      @venue_order_id,
      "Venue Adapter Cancel Raised Error"
    )

    assert {:ok, _} = Tai.Orders.cancel(order)

    assert_receive {
      :callback_fired,
      %Tai.Orders.Order{status: :pending_cancel},
      %Tai.Orders.Order{status: :cancel_error} = error_order
    }

    assert {:unhandled, {error, [stack_1 | _]}} = error_order.error_reason
    assert error_order.last_received_at != open_order.last_received_at
    assert error == %RuntimeError{message: "Venue Adapter Cancel Raised Error"}
    assert {Tai.VenueAdapters.Mock, _, _, [file: _, line: _]} = stack_1
  end
end
