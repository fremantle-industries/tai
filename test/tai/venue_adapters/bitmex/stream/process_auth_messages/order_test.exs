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

  describe "update" do
    test "updates each order with a time in force = gtc" do
      Tai.Events.firehose_subscribe()
      order_1 = enqueue_order(:buy, %{price: Decimal.new(100), qty: Decimal.new(5)})
      order_2 = enqueue_order(:sell, %{price: Decimal.new(1500), qty: Decimal.new(15)})
      order_3 = enqueue_order(:sell_ioc, %{price: Decimal.new(1200), qty: Decimal.new(45)})
      venue_order_id_1 = "7cb830ba-81a2-459d-9b46-0f0889c76ad1"
      venue_order_id_2 = "1748ac55-64af-4a4f-908f-156d1aabd947"
      venue_order_id_3 = "12d0807a-f8a0-46a6-8d99-de69527dac9b"

      bitmex_orders = [
        %{
          "orderID" => venue_order_id_1,
          "ordStatus" => "Filled",
          "leavesQty" => 3,
          "cumQty" => 2,
          "avgPx" => 4265.5,
          "timestamp" => "2018-12-27T05:33:50.795Z"
        },
        %{
          "orderID" => venue_order_id_2,
          "ordStatus" => "Filled",
          "leavesQty" => 10,
          "cumQty" => 5,
          "avgPx" => 2000,
          "timestamp" => "2018-12-27T05:33:50.832Z"
        },
        %{
          "orderID" => venue_order_id_3,
          "ordStatus" => "Filled",
          "leavesQty" => 30,
          "cumQty" => 15,
          "avgPx" => 1000,
          "timestamp" => "2018-12-27T05:33:50.987Z"
        }
      ]

      [order_1, order_2, order_3] |> set_venue_order_ids(bitmex_orders)

      :my_venue
      |> ProcessAuthMessages.to_name()
      |> GenServer.cast(
        {%{"table" => "order", "action" => "update", "data" => bitmex_orders}, :ignore}
      )

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{side: :buy, time_in_force: :gtc} =
                        buy_updated_event}

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{side: :sell, time_in_force: :gtc} =
                        sell_updated_event}

      refute_receive {Tai.Event, %Tai.Events.OrderUpdated{time_in_force: :ioc}}

      assert buy_updated_event.venue_order_id == venue_order_id_1
      assert buy_updated_event.status == :filled
      assert buy_updated_event.avg_price == Decimal.new("4265.5")
      assert buy_updated_event.leaves_qty == Decimal.new(3)
      assert buy_updated_event.cumulative_qty == Decimal.new(2)
      assert buy_updated_event.qty == Decimal.new(5)
      assert %DateTime{} = buy_updated_event.venue_updated_at

      assert sell_updated_event.venue_order_id == venue_order_id_2
      assert sell_updated_event.status == :filled
      assert sell_updated_event.avg_price == Decimal.new("2000")
      assert sell_updated_event.leaves_qty == Decimal.new(10)
      assert sell_updated_event.cumulative_qty == Decimal.new(5)
      assert sell_updated_event.qty == Decimal.new(15)
      assert %DateTime{} = buy_updated_event.venue_updated_at
    end

    test "updates leaves_qty for canceled orders" do
      Tai.Events.firehose_subscribe()
      order_1 = enqueue_order(:buy, %{price: Decimal.new(100), qty: Decimal.new(5)})
      venue_order_id = "059ce250-15a6-4d84-8623-779555cf086d"

      bitmex_orders = [
        %{
          "leavesQty" => 0,
          "ordStatus" => "Canceled",
          "orderID" => venue_order_id,
          "timestamp" => "2019-01-11T02:03:06.309Z"
        }
      ]

      [order_1] |> set_venue_order_ids(bitmex_orders)

      :my_venue
      |> ProcessAuthMessages.to_name()
      |> GenServer.cast(
        {%{"table" => "order", "action" => "update", "data" => bitmex_orders}, :ignore}
      )

      assert_receive {Tai.Event, %Tai.Events.OrderUpdated{} = event_1}

      assert event_1.venue_order_id == venue_order_id
      assert event_1.status == :canceled
      assert event_1.leaves_qty == Decimal.new(0)
      assert event_1.qty == Decimal.new(5)
      assert %DateTime{} = event_1.venue_updated_at
    end
  end

  defp enqueue_order(:buy, attrs) do
    Tai.Trading.OrderSubmissions.BuyLimitGtc
    |> enqueue_order(attrs)
  end

  defp enqueue_order(:sell, attrs) do
    Tai.Trading.OrderSubmissions.SellLimitGtc
    |> enqueue_order(attrs)
  end

  defp enqueue_order(:sell_ioc, attrs) do
    Tai.Trading.OrderSubmissions.SellLimitIoc
    |> enqueue_order(attrs)
  end

  defp enqueue_order(submission_type, attrs) do
    {:ok, order} =
      submission_type
      |> struct(attrs)
      |> Tai.Trading.OrderStore.add()

    order
  end

  defp set_venue_order_ids(orders, bitmex_orders) do
    orders
    |> Enum.zip(bitmex_orders)
    |> Enum.each(fn {order, venue_order} ->
      {:ok, {_prev_order, _updated_order}} =
        Tai.Trading.OrderStore.find_by_and_update(
          [client_id: order.client_id],
          venue_order_id: Map.get(venue_order, "orderID")
        )
    end)
  end
end
