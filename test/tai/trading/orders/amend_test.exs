defmodule Tai.Trading.Orders.AmendTest do
  use ExUnit.Case, async: false

  import Tai.TestSupport.Helpers
  alias Tai.TestSupport.Mocks

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai)
    end)

    start_supervised!(Mocks.Server)
    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"

  describe "success" do
    setup do
      submission =
        Support.OrderSubmissions.build(Tai.Trading.OrderSubmissions.BuyLimitGtc, %{
          order_updated_callback: fire_order_callback(self())
        })

      Mocks.Responses.Orders.GoodTillCancel.unfilled(@venue_order_id, submission)

      assert {:ok, _} = Tai.Trading.Orders.create(submission)

      assert_receive {:callback_fired, _,
                      %Tai.Trading.Order{side: :buy, status: :open} = open_order}

      {:ok, %{order: open_order}}
    end

    test "pends the order while amending and broadcasts the status change events", %{
      order: open_order
    } do
      amend_price = Decimal.new("105.5")
      amend_qty = Decimal.new(10)
      Tai.Events.firehose_subscribe()

      Mocks.Responses.Orders.GoodTillCancel.amend_price_and_qty(
        open_order,
        amend_price,
        amend_qty
      )

      assert {:ok, %Tai.Trading.Order{} = pending_amend_order} =
               Tai.Trading.Orders.amend(open_order, %{
                 price: amend_price,
                 size: amend_qty
               })

      assert pending_amend_order.venue_order_id == @venue_order_id
      assert pending_amend_order.side == :buy
      assert pending_amend_order.status == :pending_amend
      assert pending_amend_order.price != amend_price
      assert pending_amend_order.size != amend_qty

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{side: :buy, status: :open},
        %Tai.Trading.Order{side: :buy, status: :pending_amend}
      }

      assert_receive {
        :callback_fired,
        %Tai.Trading.Order{side: :buy, status: :pending_amend},
        %Tai.Trading.Order{side: :buy, status: :open} = amended_order
      }

      assert amended_order.venue_order_id == @venue_order_id
      assert amended_order.price == amend_price
      assert amended_order.size == amend_qty
    end

    test "broadcasts the status changes", %{order: open_order} do
      amend_price = Decimal.new("105.5")
      Tai.Events.firehose_subscribe()

      Mocks.Responses.Orders.GoodTillCancel.amend_price(open_order, amend_price)

      assert {:ok, %Tai.Trading.Order{} = pending_amend_order} =
               Tai.Trading.Orders.amend(
                 open_order,
                 %{price: amend_price}
               )

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{side: :buy, status: :pending_amend} =
                        pending_amend_event}

      assert pending_amend_event.venue_order_id == @venue_order_id
      assert pending_amend_event.price != amend_price

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{side: :buy, status: :open} = amended_order_event}

      assert amended_order_event.venue_order_id == @venue_order_id
      assert amended_order_event.price == amend_price
    end
  end

  describe "errors" do
    setup do
      submission =
        Support.OrderSubmissions.build(Tai.Trading.OrderSubmissions.BuyLimitGtc, %{
          order_updated_callback: fire_order_callback(self())
        })

      {:ok, enqueued_order} = Tai.Trading.OrderStore.add(submission)
      {:ok, %{order: enqueued_order}}
    end

    test "returns an error tuple when the order is not open", %{order: enqueued_order} do
      assert {:error, :order_status_must_be_open} =
               Tai.Trading.Orders.amend(enqueued_order, %{price: Decimal.new(1)})
    end

    test "broadcasts an event when the order is not open", %{order: enqueued_order} do
      Tai.Events.firehose_subscribe()

      Tai.Trading.Orders.amend(enqueued_order, %{price: Decimal.new(1)})

      assert_receive {Tai.Event, %Tai.Events.OrderErrorAmendHasInvalidStatus{} = event}
      assert event.client_id != nil
      assert event.was == :enqueued
      assert event.required == :open
    end
  end
end
