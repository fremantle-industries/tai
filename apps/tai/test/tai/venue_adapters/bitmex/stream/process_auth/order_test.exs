defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.OrderTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Assertions.Event
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth
  alias Tai.VenueAdapters.Bitmex.ClientId
  alias Tai.Events

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
      Events.firehose_subscribe()
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
          "leavesQty" => 30,
          "orderQty" => 50,
          "price" => 2000,
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
        {%{"table" => "order", "action" => "update", "data" => bitmex_orders}, Timex.now()}
      )

      assert_event(
        %Events.OrderUpdated{
          side: :buy,
          time_in_force: :gtc,
          status: :filled
        } = buy_filled_updated_event
      )

      assert_event(
        %Events.OrderUpdated{
          side: :sell,
          time_in_force: :gtc,
          status: :partially_filled
        } = sell_partially_filled_updated_event
      )

      refute_event(%Events.OrderUpdated{time_in_force: :ioc})
      refute_event(%Events.OrderUpdated{time_in_force: :gtc})

      assert buy_filled_updated_event.client_id == order_1.client_id
      assert buy_filled_updated_event.leaves_qty == Decimal.new(0)
      assert buy_filled_updated_event.cumulative_qty == Decimal.new(5)
      assert buy_filled_updated_event.qty == Decimal.new(5)
      assert %DateTime{} = buy_filled_updated_event.last_received_at
      assert %DateTime{} = buy_filled_updated_event.last_venue_timestamp

      assert sell_partially_filled_updated_event.client_id == order_2.client_id
      assert sell_partially_filled_updated_event.leaves_qty == Decimal.new(30)
      assert sell_partially_filled_updated_event.cumulative_qty == Decimal.new(20)
      assert sell_partially_filled_updated_event.qty == Decimal.new(10)
      assert %DateTime{} = buy_filled_updated_event.last_received_at
      assert %DateTime{} = buy_filled_updated_event.last_venue_timestamp
    end

    test "updates leaves_qty for canceled orders" do
      Events.firehose_subscribe()
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
        {%{"table" => "order", "action" => "update", "data" => bitmex_orders}, Timex.now()}
      )

      assert_event(%Events.OrderUpdated{} = event)

      assert event.status == :canceled
      assert event.leaves_qty == Decimal.new(0)
      assert event.qty == Decimal.new(5)
      assert %DateTime{} = event.last_received_at
      assert %DateTime{} = event.last_venue_timestamp
    end

    test "broadcasts an event when the status is invalid" do
      Events.firehose_subscribe()
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
          "orderQty" => 10,
          "price" => 2000,
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

      assert_event(
        %Events.OrderUpdateInvalidStatus{
          action: Tai.Trading.OrderStore.Actions.PassiveFill
        } = passive_fill_invalid_event
      )

      assert passive_fill_invalid_event.client_id == order_1.client_id
      assert passive_fill_invalid_event.was == :enqueued

      assert passive_fill_invalid_event.required == [
               :open,
               :partially_filled,
               :pending_amend,
               :pending_cancel,
               :amend_error,
               :cancel_error
             ]

      assert_event(
        %Events.OrderUpdateInvalidStatus{
          action: Tai.Trading.OrderStore.Actions.PassivePartialFill
        } = passive_partial_fill_invalid_event
      )

      assert passive_partial_fill_invalid_event.client_id == order_2.client_id
      assert passive_partial_fill_invalid_event.was == :enqueued

      assert passive_partial_fill_invalid_event.required == [
               :open,
               :partially_filled,
               :pending_amend,
               :pending_cancel,
               :amend_error,
               :cancel_error
             ]

      assert_event(
        %Events.OrderUpdateInvalidStatus{
          action: Tai.Trading.OrderStore.Actions.PassiveCancel
        } = passive_cancel_invalid_event
      )

      assert passive_cancel_invalid_event.client_id == order_3.client_id
      assert passive_cancel_invalid_event.was == :enqueued

      assert passive_cancel_invalid_event.required == [
               :rejected,
               :open,
               :partially_filled,
               :filled,
               :expired,
               :pending_amend,
               :amend,
               :amend_error,
               :pending_cancel,
               :cancel_accepted
             ]
    end

    test "broadcasts an event when the order can't be found" do
      Events.firehose_subscribe()
      canceled_client_id = Ecto.UUID.generate()
      partially_filled_client_id = Ecto.UUID.generate()
      filled_client_id = Ecto.UUID.generate()

      bitmex_orders = [
        %{
          "clOrdID" => canceled_client_id |> ClientId.to_venue(:gtc),
          "leavesQty" => 0,
          "ordStatus" => "Canceled",
          "timestamp" => "2019-01-11T02:03:06.309Z"
        },
        %{
          "clOrdID" => partially_filled_client_id |> ClientId.to_venue(:gtc),
          "ordStatus" => "PartiallyFilled",
          "leavesQty" => 3,
          "orderQty" => 10,
          "price" => 2000,
          "timestamp" => "2018-12-27T05:33:50.832Z"
        },
        %{
          "clOrdID" => filled_client_id |> ClientId.to_venue(:gtc),
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

      assert_event(
        %Events.OrderUpdateNotFound{
          action: Tai.Trading.OrderStore.Actions.PassiveCancel
        } = canceled_not_found_event
      )

      assert canceled_not_found_event.client_id == canceled_client_id

      assert_event(
        %Events.OrderUpdateNotFound{
          action: Tai.Trading.OrderStore.Actions.PassivePartialFill
        } = partially_filled_not_found_event
      )

      assert partially_filled_not_found_event.client_id == partially_filled_client_id

      assert_event(
        %Events.OrderUpdateNotFound{
          action: Tai.Trading.OrderStore.Actions.PassiveFill
        } = filled_not_found_event
      )

      assert filled_not_found_event.client_id == filled_client_id
    end

    test "broadcasts an event when the message can't be handled" do
      Events.firehose_subscribe()
      bitmex_orders = [%{"unhandled" => true}]

      :my_venue
      |> ProcessAuth.to_name()
      |> GenServer.cast(
        {%{"table" => "order", "action" => "update", "data" => bitmex_orders}, :ignore}
      )

      assert_event(%Events.StreamMessageUnhandled{} = not_found_event)
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
        cumulative_qty: Decimal.new(0),
        leaves_qty: order.qty,
        last_received_at: Timex.now(),
        last_venue_timestamp: Timex.now()
      }
      |> Tai.Trading.OrderStore.update()

    open_order
  end
end
