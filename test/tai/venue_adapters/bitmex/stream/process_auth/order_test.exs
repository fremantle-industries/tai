defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.OrderTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth
  alias Tai.VenueAdapters.Bitmex.ClientId

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    start_supervised!({ProcessAuth, [venue_id: :my_venue]})
    :ok
  end

  describe "update" do
    test "updates each gtc order with a status" do
      Tai.Events.firehose_subscribe()
      order_1 = :buy |> enqueue(%{price: Decimal.new(100), qty: Decimal.new(5)}) |> open()
      order_2 = :sell |> enqueue(%{price: Decimal.new(1500), qty: Decimal.new(10)}) |> open()
      order_3 = :sell_ioc |> enqueue(%{price: Decimal.new(1200), qty: Decimal.new(45)})
      order_4 = :buy |> enqueue(%{price: Decimal.new(300), qty: Decimal.new(3)}) |> open()

      bitmex_orders = [
        %{
          "clOrdID" => order_4.client_id |> ClientId.to_venue(order_4.time_in_force),
          "leavesQty" => 30,
          "cumQty" => 15,
          "avgPx" => 1000,
          "timestamp" => "2018-12-27T05:33:50.987Z"
        },
        %{
          "clOrdID" => order_3.client_id |> ClientId.to_venue(order_3.time_in_force),
          "ordStatus" => "Filled",
          "leavesQty" => 30,
          "cumQty" => 15,
          "timestamp" => "2018-12-27T05:33:50.987Z"
        },
        %{
          "clOrdID" => order_2.client_id |> ClientId.to_venue(order_2.time_in_force),
          "ordStatus" => "PartiallyFilled",
          "leavesQty" => 3,
          "cumQty" => 7,
          "avgPx" => 2000,
          "timestamp" => "2018-12-27T05:33:50.832Z"
        },
        %{
          "clOrdID" => order_1.client_id |> ClientId.to_venue(order_1.time_in_force),
          "ordStatus" => "Filled",
          "leavesQty" => 0,
          "cumQty" => 5,
          "timestamp" => "2018-12-27T05:33:50.795Z"
        }
      ]

      :my_venue
      |> ProcessAuth.to_name()
      |> GenServer.cast(
        {%{"table" => "order", "action" => "update", "data" => bitmex_orders}, :ignore}
      )

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{side: :buy, time_in_force: :gtc} =
                        buy_updated_event, _}

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdated{side: :sell, time_in_force: :gtc} =
                        sell_updated_event, _}

      refute_receive {Tai.Event, %Tai.Events.OrderUpdated{time_in_force: :ioc}, _}
      refute_receive {Tai.Event, %Tai.Events.OrderUpdated{time_in_force: :gtc}, _}

      assert buy_updated_event.client_id == order_1.client_id
      assert buy_updated_event.status == :filled
      assert buy_updated_event.leaves_qty == Decimal.new(0)
      assert buy_updated_event.cumulative_qty == Decimal.new(5)
      assert buy_updated_event.qty == Decimal.new(5)
      assert %DateTime{} = buy_updated_event.last_received_at
      assert %DateTime{} = buy_updated_event.last_venue_timestamp

      assert sell_updated_event.client_id == order_2.client_id
      assert sell_updated_event.status == :open
      assert sell_updated_event.avg_price == Decimal.new("2000")
      assert sell_updated_event.leaves_qty == Decimal.new(3)
      assert sell_updated_event.cumulative_qty == Decimal.new(7)
      assert sell_updated_event.qty == Decimal.new(10)
      assert %DateTime{} = buy_updated_event.last_received_at
      assert %DateTime{} = buy_updated_event.last_venue_timestamp
    end

    test "updates leaves_qty for canceled orders" do
      Tai.Events.firehose_subscribe()
      order = :buy |> enqueue(%{price: Decimal.new(100), qty: Decimal.new(5)}) |> open()

      bitmex_orders = [
        %{
          "clOrdID" => order.client_id |> ClientId.to_venue(order.time_in_force),
          "leavesQty" => 0,
          "ordStatus" => "Canceled",
          "timestamp" => "2019-01-11T02:03:06.309Z"
        }
      ]

      :my_venue
      |> ProcessAuth.to_name()
      |> GenServer.cast(
        {%{"table" => "order", "action" => "update", "data" => bitmex_orders}, :ignore}
      )

      assert_receive {Tai.Event, %Tai.Events.OrderUpdated{} = event, _}

      assert event.status == :canceled
      assert event.leaves_qty == Decimal.new(0)
      assert event.qty == Decimal.new(5)
      assert %DateTime{} = event.last_received_at
      assert %DateTime{} = event.last_venue_timestamp
    end

    test "broadcasts an event when the status is invalid" do
      Tai.Events.firehose_subscribe()
      order_1 = :buy |> enqueue(%{price: Decimal.new(100), qty: Decimal.new(5)})
      order_2 = :sell |> enqueue(%{price: Decimal.new(1500), qty: Decimal.new(10)})
      order_3 = :buy |> enqueue(%{price: Decimal.new(100), qty: Decimal.new(5)})

      bitmex_orders = [
        %{
          "clOrdID" => order_3.client_id |> ClientId.to_venue(order_3.time_in_force),
          "leavesQty" => 0,
          "ordStatus" => "Canceled",
          "timestamp" => "2019-01-11T02:03:06.309Z"
        },
        %{
          "clOrdID" => order_2.client_id |> ClientId.to_venue(order_2.time_in_force),
          "ordStatus" => "PartiallyFilled",
          "leavesQty" => 3,
          "cumQty" => 7,
          "avgPx" => 2000,
          "timestamp" => "2018-12-27T05:33:50.832Z"
        },
        %{
          "clOrdID" => order_1.client_id |> ClientId.to_venue(order_1.time_in_force),
          "ordStatus" => "Filled",
          "leavesQty" => 0,
          "cumQty" => 5,
          "avgPx" => 4265.5,
          "timestamp" => "2018-12-27T05:33:50.795Z"
        }
      ]

      :my_venue
      |> ProcessAuth.to_name()
      |> GenServer.cast(
        {%{"table" => "order", "action" => "update", "data" => bitmex_orders}, :ignore}
      )

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdateInvalidStatus{action: :passive_fill} =
                        passive_fill_invalid_event, _}

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdateInvalidStatus{action: :passive_partial_fill} =
                        passive_partial_fill_invalid_event, _}

      assert_receive {Tai.Event,
                      %Tai.Events.OrderUpdateInvalidStatus{action: :passive_cancel} =
                        passive_cancel_invalid_event, _}

      assert passive_fill_invalid_event.client_id == order_1.client_id
      assert passive_fill_invalid_event.action == :passive_fill
      assert passive_fill_invalid_event.was == :enqueued

      assert passive_fill_invalid_event.required == [
               :open,
               :pending_amend,
               :pending_cancel,
               :amend_error,
               :cancel_error
             ]

      assert passive_partial_fill_invalid_event.client_id == order_2.client_id
      assert passive_partial_fill_invalid_event.action == :passive_partial_fill
      assert passive_partial_fill_invalid_event.was == :enqueued

      assert passive_partial_fill_invalid_event.required == [
               :open,
               :pending_amend,
               :pending_cancel,
               :amend_error,
               :cancel_error
             ]

      assert passive_cancel_invalid_event.client_id == order_3.client_id
      assert passive_cancel_invalid_event.action == :passive_cancel
      assert passive_cancel_invalid_event.was == :enqueued

      assert passive_cancel_invalid_event.required == [
               :open,
               :expired,
               :filled,
               :pending_amend,
               :amend,
               :amend_error,
               :pending_cancel,
               :cancel_accepted
             ]
    end

    test "broadcasts an event when the order can't be found" do
      Tai.Events.firehose_subscribe()
      client_id = Ecto.UUID.generate()

      bitmex_orders = [
        %{
          "clOrdID" => client_id |> ClientId.to_venue(:gtc),
          "leavesQty" => 0,
          "ordStatus" => "Canceled",
          "timestamp" => "2019-01-11T02:03:06.309Z"
        }
      ]

      :my_venue
      |> ProcessAuth.to_name()
      |> GenServer.cast(
        {%{"table" => "order", "action" => "update", "data" => bitmex_orders}, :ignore}
      )

      assert_receive {Tai.Event, %Tai.Events.OrderUpdateNotFound{} = not_found_event, _}
      assert not_found_event.client_id == client_id
      assert not_found_event.action == :passive_cancel
    end
  end

  defp enqueue(:buy, attrs) do
    Tai.Trading.OrderSubmissions.BuyLimitGtc
    |> enqueue(attrs)
  end

  defp enqueue(:sell, attrs) do
    Tai.Trading.OrderSubmissions.SellLimitGtc
    |> enqueue(attrs)
  end

  defp enqueue(:sell_ioc, attrs) do
    Tai.Trading.OrderSubmissions.SellLimitIoc
    |> enqueue(attrs)
  end

  defp enqueue(submission_type, attrs) do
    {:ok, order} =
      submission_type
      |> struct(attrs)
      |> Tai.Trading.OrderStore.enqueue()

    order
  end

  defp open(order, venue_order_id \\ Ecto.UUID.generate()) do
    {:ok, {_, open_order}} =
      %Tai.Trading.OrderStore.Actions.Open{
        client_id: order.client_id,
        venue_order_id: venue_order_id,
        avg_price: order.price,
        cumulative_qty: Decimal.new(0),
        leaves_qty: order.qty,
        last_received_at: Timex.now(),
        last_venue_timestamp: Timex.now()
      }
      |> Tai.Trading.OrderStore.update()

    open_order
  end
end
