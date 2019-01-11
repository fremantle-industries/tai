defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuthMessages.OrderTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuthMessages

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    start_supervised!({ProcessAuthMessages, [venue_id: :my_venue]})
    :ok
  end

  @venue_order_id "7f3bae18-b96d-6d4d-27f0-a11f52d4b6b4"

  describe "update" do
    test "updates each order" do
      Tai.Events.firehose_subscribe()

      {:ok, order_1} =
        Tai.Trading.OrderSubmissions.BuyLimitGtc
        |> struct(%{price: Decimal.new(100), qty: Decimal.new(5)})
        |> Tai.Trading.OrderStore.add()

      bitmex_orders = [
        %{
          "orderID" => @venue_order_id,
          "ordStatus" => "Filled",
          "leavesQty" => 3,
          "cumQty" => 2,
          "avgPx" => 4265.5,
          "timestamp" => "2018-12-27T05:33:50.795Z"
        }
      ]

      [order_1]
      |> Enum.zip(bitmex_orders)
      |> Enum.each(fn {order, venue_order} ->
        {:ok, {_prev_order, _updated_order}} =
          Tai.Trading.OrderStore.find_by_and_update(
            [client_id: order.client_id],
            venue_order_id: Map.get(venue_order, "orderID")
          )
      end)

      :my_venue
      |> ProcessAuthMessages.to_name()
      |> GenServer.cast(
        {%{"table" => "order", "action" => "update", "data" => bitmex_orders}, :ignore}
      )

      assert_receive {Tai.Event, %Tai.Events.OrderUpdated{} = event_1}

      assert event_1.venue_order_id == @venue_order_id
      assert event_1.status == :filled
      assert event_1.avg_price == Decimal.new("4265.5")
      assert event_1.leaves_qty == Decimal.new(3)
      assert event_1.cumulative_qty == Decimal.new(2)
      assert event_1.qty == Decimal.new(5)
      assert %DateTime{} = event_1.venue_updated_at
    end

    test "updates leaves_qty for canceled orders" do
      Tai.Events.firehose_subscribe()

      {:ok, order_1} =
        Tai.Trading.OrderSubmissions.BuyLimitGtc
        |> struct(%{price: Decimal.new(100), qty: Decimal.new(5)})
        |> Tai.Trading.OrderStore.add()

      bitmex_orders = [
        %{
          "leavesQty" => 0,
          "ordStatus" => "Canceled",
          "orderID" => @venue_order_id,
          "timestamp" => "2019-01-11T02:03:06.309Z"
        }
      ]

      [order_1]
      |> Enum.zip(bitmex_orders)
      |> Enum.each(fn {order, venue_order} ->
        {:ok, {_prev_order, _updated_order}} =
          Tai.Trading.OrderStore.find_by_and_update(
            [client_id: order.client_id],
            venue_order_id: Map.get(venue_order, "orderID")
          )
      end)

      :my_venue
      |> ProcessAuthMessages.to_name()
      |> GenServer.cast(
        {%{"table" => "order", "action" => "update", "data" => bitmex_orders}, :ignore}
      )

      assert_receive {Tai.Event, %Tai.Events.OrderUpdated{} = event_1}

      assert event_1.venue_order_id == @venue_order_id
      assert event_1.status == :canceled
      assert event_1.leaves_qty == Decimal.new(0)
      assert event_1.qty == Decimal.new(5)
      assert %DateTime{} = event_1.venue_updated_at
    end

    test "broadcasts an event when an order can't be found" do
      Tai.Events.firehose_subscribe()

      bitmex_orders = [
        %{
          "leavesQty" => 0,
          "ordStatus" => "Canceled",
          "orderID" => @venue_order_id,
          "timestamp" => "2019-01-11T02:03:06.309Z"
        }
      ]

      :my_venue
      |> ProcessAuthMessages.to_name()
      |> GenServer.cast(
        {%{"table" => "order", "action" => "update", "data" => bitmex_orders}, :ignore}
      )

      assert_receive {Tai.Event, %Tai.Events.OrderNotFound{} = not_found_event}
      assert not_found_event.venue_order_id == @venue_order_id
    end
  end
end
