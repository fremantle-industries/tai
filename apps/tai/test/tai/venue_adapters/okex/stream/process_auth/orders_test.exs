defmodule Tai.VenueAdapters.OkEx.Stream.ProcessAuth.OrdersTest do
  use Tai.TestSupport.DataCase, async: false
  import Tai.TestSupport.Assertions.Event
  alias Tai.VenueAdapters.OkEx.Stream.ProcessAuth
  alias Tai.VenueAdapters.OkEx.ClientId
  alias Tai.NewOrders

  @venue :my_venue
  @received_at Tai.Time.monotonic_time()

  setup do
    TaiEvents.firehose_subscribe()
    Phoenix.PubSub.subscribe(Tai.PubSub, "order_updated:*")
    start_supervised!({ProcessAuth, [venue: @venue]})
    :ok
  end

  test "cancels an order" do
    {:ok, open_order} = create_open_order()
    open_order_client_id = open_order.client_id
    venue_client_id = open_order_client_id |> to_venue_client_id()
    venue_order_data = build_venue_order(%{
      "client_oid" => venue_client_id, "state" => "-1"
    })

    cast_order_msg(%{"table" => "futures/order", "data" => [venue_order_data]})

    assert_receive {:order_updated, ^open_order_client_id, %NewOrders.Transitions.Cancel{}}
    order = NewOrders.OrderRepo.get!(NewOrders.Order, open_order_client_id)
    assert order.status == :canceled
  end

  test "opens an order" do
    {:ok, enqueued_order_1} = create_enqueued_order()
    enqueued_order_1_client_id = enqueued_order_1.client_id
    venue_client_id_1 = enqueued_order_1_client_id |> to_venue_client_id()
    venue_order_data_1 = build_venue_order(%{
      "client_oid" => venue_client_id_1, "state" => "0", "size" => "1", "filled_qty" => "0"
    })

    {:ok, enqueued_order_2} = create_enqueued_order()
    enqueued_order_2_client_id = enqueued_order_2.client_id
    venue_client_id_2 = enqueued_order_2_client_id |> to_venue_client_id()
    venue_order_data_2 = build_venue_order(%{
      "client_oid" => venue_client_id_2, "state" => "0", "size" => "1", "filled_size" => "0"
    })

    cast_order_msg(%{
      "table" => "futures/order",
      "data" => [venue_order_data_1, venue_order_data_2]
    })

    assert_receive {:order_updated, ^enqueued_order_1_client_id, %NewOrders.Transitions.Open{}}
    order_1 = NewOrders.OrderRepo.get!(NewOrders.Order, enqueued_order_1_client_id)
    assert order_1.status == :open
    assert order_1.cumulative_qty == Decimal.new(0)
    assert order_1.leaves_qty == Decimal.new(1)

    assert_receive {:order_updated, ^enqueued_order_2_client_id, %NewOrders.Transitions.Open{}}
    order_2 = NewOrders.OrderRepo.get!(NewOrders.Order, enqueued_order_2_client_id)
    assert order_2.status == :open
    assert order_2.cumulative_qty == Decimal.new(0)
    assert order_2.leaves_qty == Decimal.new(1)
  end

  test "partially fills an order" do
    {:ok, enqueued_order_1} = create_enqueued_order()
    enqueued_order_1_client_id = enqueued_order_1.client_id
    venue_client_id_1 = enqueued_order_1_client_id |> to_venue_client_id()
    venue_order_data_1 = build_venue_order(%{
      "client_oid" => venue_client_id_1, "state" => "1", "size" => "1", "filled_qty" => "0.3"
    })

    {:ok, enqueued_order_2} = create_enqueued_order()
    enqueued_order_2_client_id = enqueued_order_2.client_id
    venue_client_id_2 = enqueued_order_2_client_id |> to_venue_client_id()
    venue_order_data_2 = build_venue_order(%{
      "client_oid" => venue_client_id_2, "state" => "1", "size" => "1", "filled_size" => "0.6"
    })

    cast_order_msg(%{
      "table" => "futures/order",
      "data" => [venue_order_data_1, venue_order_data_2]
    })

    assert_receive {:order_updated, ^enqueued_order_1_client_id, %NewOrders.Transitions.PartialFill{}}
    order_1 = NewOrders.OrderRepo.get!(NewOrders.Order, enqueued_order_1_client_id)
    assert order_1.status == :open
    assert order_1.cumulative_qty == Decimal.new("0.3")
    assert order_1.leaves_qty == Decimal.new("0.7")

    assert_receive {:order_updated, ^enqueued_order_2_client_id, %NewOrders.Transitions.PartialFill{}}
    order_2 = NewOrders.OrderRepo.get!(NewOrders.Order, enqueued_order_2_client_id)
    assert order_2.status == :open
    assert order_2.cumulative_qty == Decimal.new("0.6")
    assert order_2.leaves_qty == Decimal.new("0.4")
  end

  test "fills an order" do
    {:ok, enqueued_order_1} = create_enqueued_order()
    enqueued_order_1_client_id = enqueued_order_1.client_id
    venue_client_id_1 = enqueued_order_1_client_id |> to_venue_client_id()
    venue_order_data_1 = build_venue_order(%{
      "client_oid" => venue_client_id_1, "state" => "2", "size" => "2", "filled_qty" => "2"
    })

    {:ok, enqueued_order_2} = create_enqueued_order()
    enqueued_order_2_client_id = enqueued_order_2.client_id
    venue_client_id_2 = enqueued_order_2_client_id |> to_venue_client_id()
    venue_order_data_2 = build_venue_order(%{
      "client_oid" => venue_client_id_2, "state" => "2", "size" => "1", "filled_size" => "1"
    })

    cast_order_msg(%{
      "table" => "futures/order",
      "data" => [venue_order_data_1, venue_order_data_2]
    })

    assert_receive {:order_updated, ^enqueued_order_1_client_id, %NewOrders.Transitions.Fill{}}
    order_1 = NewOrders.OrderRepo.get!(NewOrders.Order, enqueued_order_1_client_id)
    assert order_1.status == :filled
    assert order_1.cumulative_qty == Decimal.new("2")
    assert order_1.leaves_qty == Decimal.new("0")

    assert_receive {:order_updated, ^enqueued_order_2_client_id, %NewOrders.Transitions.Fill{}}
    order_2 = NewOrders.OrderRepo.get!(NewOrders.Order, enqueued_order_2_client_id)
    assert order_2.status == :filled
    assert order_2.cumulative_qty == Decimal.new("1")
    assert order_2.leaves_qty == Decimal.new("0")
  end

  test "logs a warning event when the order message has an invalid state" do
    cast_order_msg(%{
      "table" => "futures/order",
      "data" => [build_venue_order(%{"state" => "invalid state"})]
    })

    assert_event(%Tai.Events.StreamMessageUnhandled{}, :warn)
  end

  test "logs a warning event when the order message doesn't include require attributes" do
    cast_order_msg(%{
      "table" => "futures/order",
      "data" => [build_venue_order(%{})]
    })

    assert_event(%Tai.Events.StreamMessageUnhandled{}, :warn)
  end

  defp to_venue_client_id(client_id) do
    client_id |> ClientId.to_venue()
  end

  defp cast_order_msg(msg) do
    @venue
    |> ProcessAuth.process_name()
    |> GenServer.cast({msg, @received_at})
  end

  defp build_venue_order(attrs) do
    %{
      "client_oid" => Ecto.UUID.generate() |> to_venue_client_id(),
      "order_id" => "submittingOrderA",
      "timestamp" => "2019-01-05T02:03:06.309Z"
    }
    |> Map.merge(attrs)
  end

  defp create_test_order(attrs) do
    %{
      venue: @venue |> Atom.to_string(),
      credential: "main"
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
