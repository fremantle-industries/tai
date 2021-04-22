defmodule Tai.Orders.AmendErrorTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Mock
  import Support.Orders
  alias Tai.Orders.Submissions.SellLimitGtc
  alias Tai.Orders.{Order, Transitions}
  alias Tai.TestSupport.Mocks

  defmodule TestFilledProvider do
    @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"
    @venue :venue_a
    @credential :main

    def update(%Transitions.PendAmend{} = transition) do
      open_order =
        struct(Order,
          client_id: transition.client_id,
          venue_order_id: @venue_order_id,
          venue_id: @venue,
          credential_id: @credential,
          status: :open
        )

      pending_amend_order =
        struct(Order,
          client_id: open_order.client_id,
          venue_order_id: open_order.venue_order_id,
          venue_id: open_order.venue_id,
          credential_id: open_order.credential_id,
          status: :pending_amend
        )

      {:ok, {open_order, pending_amend_order}}
    end

    def update(%Transitions.Amend{} = transition) do
      {:error, {:invalid_status, :filled, [:amend_required_a, :amend_required_b], transition}}
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
    submission = Support.Orders.Submissions.build_with_callback(SellLimitGtc, @submission_attrs)

    {:ok, %{submission: submission}}
  end

  describe "with an invalid pending amend status" do
    setup(%{submission: submission}) do
      {:ok, order} = Tai.Orders.create(submission)
      assert_receive {:callback_fired, _, %Order{status: :create_error}}

      {:ok, %{order: order}}
    end

    test "returns an error", %{order: order} do
      assert {:error, reason} = Tai.Orders.amend(order, %{})
      assert {:invalid_status, :create_error, required_status, transition} = reason
      assert required_status == [:open, :partially_filled, :amend_error]
      assert %Transitions.PendAmend{} = transition
    end

    test "emits an invalid status warning", %{order: order} do
      TaiEvents.firehose_subscribe()

      Tai.Orders.amend(order, %{})

      assert_receive {TaiEvents.Event, %Tai.Events.OrderUpdateInvalidStatus{} = event, :warn}
      assert event.transition == Transitions.PendAmend
    end
  end

  test "invalid amend status emits an event" do
    open_order = struct(Order, client_id: "abc123", venue_order_id: @venue_order_id)
    Mocks.Responses.Orders.GoodTillCancel.amend_price(open_order, Decimal.new(1))
    TaiEvents.firehose_subscribe()

    Tai.Orders.amend(
      open_order,
      %{price: Decimal.new(1)},
      TestFilledProvider
    )

    assert_receive {
      TaiEvents.Event,
      %Tai.Events.OrderUpdateInvalidStatus{} = amend_invalid_event,
      :warn
    }

    assert amend_invalid_event.client_id == open_order.client_id
    assert amend_invalid_event.transition == Transitions.Amend
    assert amend_invalid_event.was == :filled

    assert amend_invalid_event.required == [
             :amend_required_a,
             :amend_required_b
           ]
  end

  test "venue error updates status and records the reason", %{submission: submission} do
    Mocks.Responses.Orders.GoodTillCancel.open(@venue_order_id, submission)
    {:ok, _} = Tai.Orders.create(submission)
    assert_receive {:callback_fired, _, %Order{status: :open} = open_order}

    Tai.Orders.amend(open_order, %{})

    assert_receive {
      :callback_fired,
      %Order{status: :pending_amend},
      %Order{status: :amend_error} = error_order
    }

    assert error_order.error_reason == :mock_not_found
    assert error_order.last_received_at != open_order.last_received_at
  end

  test "rescues adapter errors", %{submission: submission} do
    Mocks.Responses.Orders.GoodTillCancel.open(@venue_order_id, submission)
    {:ok, _order} = Tai.Orders.create(submission)
    assert_receive {:callback_fired, _, %Order{status: :open} = open_order}
    Mocks.Responses.Orders.Error.amend_raise(open_order, %{}, "Venue Adapter Amend Raised Error")

    Tai.Orders.amend(open_order, %{})

    assert_receive {
      :callback_fired,
      %Order{status: :pending_amend},
      %Order{status: :amend_error} = error_order
    }

    assert {:unhandled, {error, [stack_1 | _]}} = error_order.error_reason
    assert %DateTime{} = error_order.last_received_at
    assert error == %RuntimeError{message: "Venue Adapter Amend Raised Error"}
    assert {Tai.VenueAdapters.Mock, _, _, [file: _, line: _]} = stack_1
  end
end
