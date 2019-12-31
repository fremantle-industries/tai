defmodule Tai.Trading.Orders.AmendErrorTest do
  use ExUnit.Case, async: false
  alias Tai.Trading.OrderSubmissions.SellLimitGtc
  alias Tai.Trading.{Order, Orders, OrderStore}
  alias Tai.Events
  alias Tai.TestSupport.Mocks

  defmodule TestFilledProvider do
    @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"
    @venue :test_exchange_a
    @credential :main

    def update(%OrderStore.Actions.PendAmend{} = action) do
      open_order =
        struct(Order,
          client_id: action.client_id,
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

    def update(%OrderStore.Actions.Amend{} = action) do
      {:error, {:invalid_status, :filled, [:amend_required_a, :amend_required_b], action}}
    end
  end

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai)
    end)

    start_supervised!(Mocks.Server)
    {:ok, _} = Application.ensure_all_started(:tai)

    submission = Support.OrderSubmissions.build_with_callback(SellLimitGtc)

    {:ok, %{submission: submission}}
  end

  describe "with an invalid pending amend status" do
    setup(%{submission: submission}) do
      {:ok, order} = Orders.create(submission)
      assert_receive {:callback_fired, _, %Order{status: :create_error}}

      {:ok, %{order: order}}
    end

    test "returns an error", %{order: order} do
      assert {:error, reason} = Orders.amend(order, %{})
      assert {:invalid_status, :create_error, required_status, action} = reason
      assert required_status == [:open, :partially_filled, :amend_error]
      assert %OrderStore.Actions.PendAmend{} = action
    end

    test "emits an invalid status warning", %{order: order} do
      Tai.Events.firehose_subscribe()

      Orders.amend(order, %{})

      assert_receive {Tai.Event, %Tai.Events.OrderUpdateInvalidStatus{} = event, :warn}
      assert event.action == OrderStore.Actions.PendAmend
    end
  end

  test "invalid amend status emits an event" do
    open_order = struct(Order, client_id: "abc123", venue_order_id: @venue_order_id)
    Mocks.Responses.Orders.GoodTillCancel.amend_price(open_order, Decimal.new(1))
    Events.firehose_subscribe()

    Orders.amend(
      open_order,
      %{price: Decimal.new(1)},
      TestFilledProvider
    )

    assert_receive {
      Tai.Event,
      %Events.OrderUpdateInvalidStatus{} = amend_invalid_event,
      :warn
    }

    assert amend_invalid_event.client_id == open_order.client_id
    assert amend_invalid_event.action == OrderStore.Actions.Amend
    assert amend_invalid_event.was == :filled

    assert amend_invalid_event.required == [
             :amend_required_a,
             :amend_required_b
           ]
  end

  test "venue error updates status and records the reason", %{submission: submission} do
    Mocks.Responses.Orders.GoodTillCancel.open(@venue_order_id, submission)
    {:ok, _} = Orders.create(submission)
    assert_receive {:callback_fired, _, %Order{status: :open} = open_order}

    Orders.amend(open_order, %{})

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
    {:ok, _order} = Orders.create(submission)
    assert_receive {:callback_fired, _, %Order{status: :open} = open_order}
    Mocks.Responses.Orders.Error.amend_raise(open_order, %{}, "Venue Adapter Amend Raised Error")

    Orders.amend(open_order, %{})

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
