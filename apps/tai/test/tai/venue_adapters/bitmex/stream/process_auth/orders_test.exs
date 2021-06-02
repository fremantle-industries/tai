defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.OrdersTest do
  use Tai.TestSupport.DataCase, async: false
  import Tai.TestSupport.Assertions.Event
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth
  alias Tai.VenueAdapters.Bitmex.ClientId
  alias Tai.NewOrders

  @venue :my_venue
  @credential :main
  @received_at Tai.Time.monotonic_time()

  setup do
    TaiEvents.firehose_subscribe()
    Phoenix.PubSub.subscribe(Tai.PubSub, "order_updated:*")
    start_supervised!({ProcessAuth, [venue: @venue, credential: {@credential, %{}}]})
    :ok
  end

  test "cancels an order" do
    {:ok, open_order} = create_open_order()
    open_order_client_id = open_order.client_id
    venue_client_id = open_order_client_id |> to_venue_client_id()
    venue_order_data = build_venue_order(%{
      "clOrdID" => venue_client_id, "ordStatus" => "Canceled"
    })

    cast_order_msg([venue_order_data], "update")

    assert_receive {:order_updated, ^open_order_client_id, %NewOrders.Transitions.Cancel{}}
    order = NewOrders.OrderRepo.get!(NewOrders.Order, open_order_client_id)
    assert order.status == :canceled
    assert %DateTime{} = order.last_venue_timestamp
    assert %DateTime{} = order.last_received_at
  end

  test "opens an order" do
    {:ok, enqueued_order} = create_enqueued_order()
    enqueued_order_client_id = enqueued_order.client_id
    venue_client_id = enqueued_order_client_id |> to_venue_client_id()
    venue_order_data = build_venue_order(%{
      "clOrdID" => venue_client_id, "ordStatus" => "New", "leavesQty" => 1, "cumQty" => 0
    })

    cast_order_msg([venue_order_data], "update")

    assert_receive {:order_updated, ^enqueued_order_client_id, %NewOrders.Transitions.Open{}}
    order = NewOrders.OrderRepo.get!(NewOrders.Order, enqueued_order_client_id)
    assert order.status == :open
    assert order.cumulative_qty == Decimal.new(0)
    assert order.leaves_qty == Decimal.new(1)
    assert %DateTime{} = order.last_venue_timestamp
    assert %DateTime{} = order.last_received_at
  end

  test "partially fills an order" do
    {:ok, enqueued_order} = create_enqueued_order()
    enqueued_order_client_id = enqueued_order.client_id
    venue_client_id = enqueued_order_client_id |> to_venue_client_id()
    venue_order_data = build_venue_order(%{
      "clOrdID" => venue_client_id, "ordStatus" => "PartiallyFilled", "leavesQty" => 5, "cumQty" => 10
    })

    cast_order_msg([venue_order_data], "update")

    assert_receive {:order_updated, ^enqueued_order_client_id, %NewOrders.Transitions.PartialFill{}}
    order = NewOrders.OrderRepo.get!(NewOrders.Order, enqueued_order_client_id)
    assert order.status == :open
    assert order.cumulative_qty == Decimal.new(10)
    assert order.leaves_qty == Decimal.new(5)
    assert %DateTime{} = order.last_venue_timestamp
    assert %DateTime{} = order.last_received_at
  end

  test "fills an order" do
    {:ok, enqueued_order} = create_enqueued_order()
    enqueued_order_client_id = enqueued_order.client_id
    venue_client_id = enqueued_order_client_id |> to_venue_client_id()
    venue_order_data = build_venue_order(%{
      "clOrdID" => venue_client_id, "ordStatus" => "Filled", "cumQty" => 2
    })

    cast_order_msg([venue_order_data], "update")

    assert_receive {:order_updated, ^enqueued_order_client_id, %NewOrders.Transitions.Fill{}}
    order = NewOrders.OrderRepo.get!(NewOrders.Order, enqueued_order_client_id)
    assert order.status == :filled
    assert order.cumulative_qty == Decimal.new("2")
    assert order.leaves_qty == Decimal.new("0")
    assert %DateTime{} = order.last_venue_timestamp
    assert %DateTime{} = order.last_received_at
  end

  test "ignores partial and insert messsages" do
    {:ok, enqueued_order} = create_enqueued_order()
    enqueued_order_client_id = enqueued_order.client_id
    venue_client_id = enqueued_order_client_id |> to_venue_client_id()
    venue_order_data = build_venue_order(%{
      "clOrdID" => venue_client_id, "ordStatus" => "Filled", "cumQty" => 2
    })

    cast_order_msg([venue_order_data], "partial")
    refute_receive {:order_updated, _, _}

    cast_order_msg([venue_order_data], "insert")
    refute_receive {:order_updated, _, _}
  end

  test "logs a warning event when the client id has an invalid encoding" do
    data = [build_venue_order(%{"clOrdID" => "abc123", "ordStatus" => "New"})]

    cast_order_msg(data, "update")

    assert_event(%Tai.Events.StreamMessageInvalidOrderClientId{} = event, :warn)
    assert event.client_id == "abc123"
  end

  test "logs a warning event when the order message has an invalid state" do
    data = [build_venue_order(%{"ordStatus" => "invalid state"})]

    cast_order_msg(data, "update")
    assert_event(%Tai.Events.StreamMessageUnhandled{}, :warn)
  end

  test "logs a warning event when the order message doesn't include require attributes" do
    data = [build_venue_order(%{})]
    cast_order_msg(data, "update")

    assert_event(%Tai.Events.StreamMessageUnhandled{}, :warn)
  end

  defp to_venue_client_id(client_id, time_in_force \\ "gtc") do
    ClientId.to_venue(client_id, time_in_force)
  end

  defp cast_order_msg(data, action) do
    msg = %{
      "table" => "order",
      "action" => action,
      "data" => data
    }

    @venue
    |> ProcessAuth.process_name()
    |> GenServer.cast({msg, @received_at})
  end

  defp build_venue_order(attrs) do
    %{
      "clOrdID" => Ecto.UUID.generate() |> to_venue_client_id(),
      "orderID" => "submittingOrderA",
      "timestamp" => "2019-01-05T02:03:06.309Z"
    }
    |> Map.merge(attrs)
  end

  defp create_test_order(attrs) do
    %{
      venue: @venue |> Atom.to_string(),
      credential: @credential |> Atom.to_string()
    }
    |> Map.merge(attrs)
    |> create_order_with_callback()
  end

  defp create_enqueued_order(attrs \\ %{}) do
    %{status: :enqueued}
    |> Map.merge(attrs)
    |> create_test_order()
  end

  defp create_open_order(attrs \\ %{}) do
    %{status: :open}
    |> Map.merge(attrs)
    |> create_test_order()
  end
end
