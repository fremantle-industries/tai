defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuthMessages.OrderTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuthMessages
  alias Tai.VenueAdapters.Bitmex.ClientId

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    start_supervised!({ProcessAuthMessages, [venue_id: :my_venue]})
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
          "avgPx" => 1000,
          "timestamp" => "2018-12-27T05:33:50.987Z"
        },
        %{
          "clOrdID" => order_2.client_id |> ClientId.to_venue(order_2.time_in_force),
          "ordStatus" => "Filled",
          "leavesQty" => 0,
          "cumQty" => 10,
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
      refute_receive {Tai.Event, %Tai.Events.OrderUpdated{time_in_force: :gtc}}

      assert buy_updated_event.client_id == order_1.client_id
      assert buy_updated_event.status == :filled
      assert buy_updated_event.avg_price == Decimal.new("4265.5")
      assert buy_updated_event.leaves_qty == Decimal.new(0)
      assert buy_updated_event.cumulative_qty == Decimal.new(5)
      assert buy_updated_event.qty == Decimal.new(5)
      assert %DateTime{} = buy_updated_event.venue_updated_at

      assert sell_updated_event.client_id == order_2.client_id
      assert sell_updated_event.status == :filled
      assert sell_updated_event.avg_price == Decimal.new("2000")
      assert sell_updated_event.leaves_qty == Decimal.new(0)
      assert sell_updated_event.cumulative_qty == Decimal.new(10)
      assert sell_updated_event.qty == Decimal.new(10)
      assert %DateTime{} = buy_updated_event.venue_updated_at
    end

    test "updates leaves_qty for canceled orders" do
      Tai.Events.firehose_subscribe()
      order = :buy |> enqueue(%{price: Decimal.new(100), qty: Decimal.new(5)})

      bitmex_orders = [
        %{
          "clOrdID" => order.client_id |> ClientId.to_venue(order.time_in_force),
          "leavesQty" => 0,
          "ordStatus" => "Canceled",
          "timestamp" => "2019-01-11T02:03:06.309Z"
        }
      ]

      :my_venue
      |> ProcessAuthMessages.to_name()
      |> GenServer.cast(
        {%{"table" => "order", "action" => "update", "data" => bitmex_orders}, :ignore}
      )

      assert_receive {Tai.Event, %Tai.Events.OrderUpdated{} = event}

      assert event.status == :canceled
      assert event.leaves_qty == Decimal.new(0)
      assert event.qty == Decimal.new(5)
      assert %DateTime{} = event.venue_updated_at
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
      |> Tai.Trading.NewOrderStore.add()

    order
  end

  defp open(order, venue_order_id \\ Ecto.UUID.generate()) do
    {:ok, {_, open_order}} =
      order.client_id
      |> Tai.Trading.NewOrderStore.open(
        venue_order_id,
        Timex.now(),
        order.price,
        Decimal.new(0),
        order.qty
      )

    open_order
  end
end
