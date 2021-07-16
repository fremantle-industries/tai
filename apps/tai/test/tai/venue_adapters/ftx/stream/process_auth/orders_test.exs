defmodule Tai.VenueAdapters.Ftx.Stream.ProcessAuth.OrdersTest do
  use Tai.TestSupport.DataCase, async: false
  import Tai.TestSupport.Assertions.Event
  alias Tai.VenueAdapters.Ftx.Stream.ProcessAuth
  alias Tai.Orders

  @venue :my_venue
  @credential :main
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

    venue_order_data =
      build_venue_order(%{
        "clientId" => open_order_client_id,
        "status" => "closed",
        "size" => 1,
        "filledSize" => 0.5
      })

    cast_order_msg(venue_order_data, "update")

    assert_receive {:order_updated, ^open_order_client_id, %Orders.Transitions.Cancel{}}
    order = Orders.OrderRepo.get!(Orders.Order, open_order_client_id)
    assert order.status == :canceled
    assert %DateTime{} = order.last_venue_timestamp
    assert %DateTime{} = order.last_received_at
  end

  test "opens an order" do
    {:ok, enqueued_order} = create_enqueued_order()
    enqueued_order_client_id = enqueued_order.client_id

    venue_order_data =
      build_venue_order(%{
        "clientId" => enqueued_order_client_id,
        "status" => "new",
        "remainingSize" => 1,
        "filledSize" => 0
      })

    cast_order_msg(venue_order_data, "update")

    assert_receive {:order_updated, ^enqueued_order_client_id, %Orders.Transitions.Open{}}
    order = Orders.OrderRepo.get!(Orders.Order, enqueued_order_client_id)
    assert order.status == :open
    assert order.cumulative_qty == Decimal.new(0)
    assert order.leaves_qty == Decimal.new(1)
    assert %DateTime{} = order.last_venue_timestamp
    assert %DateTime{} = order.last_received_at
  end

  test "partially fills an order" do
    {:ok, enqueued_order} = create_enqueued_order()
    enqueued_order_client_id = enqueued_order.client_id

    venue_order_data =
      build_venue_order(%{
        "clientId" => enqueued_order_client_id,
        "status" => "open",
        "remainingSize" => 5,
        "filledSize" => 10
      })

    cast_order_msg(venue_order_data, "update")

    assert_receive {:order_updated, ^enqueued_order_client_id, %Orders.Transitions.PartialFill{}}
    order = Orders.OrderRepo.get!(Orders.Order, enqueued_order_client_id)
    assert order.status == :open
    assert order.cumulative_qty == Decimal.new(10)
    assert order.leaves_qty == Decimal.new(5)
    assert %DateTime{} = order.last_venue_timestamp
    assert %DateTime{} = order.last_received_at
  end

  test "fills an order" do
    {:ok, enqueued_order} = create_enqueued_order()
    enqueued_order_client_id = enqueued_order.client_id

    venue_order_data =
      build_venue_order(%{
        "clientId" => enqueued_order_client_id,
        "status" => "closed",
        "size" => 2,
        "filledSize" => 2
      })

    cast_order_msg(venue_order_data, "update")

    assert_receive {:order_updated, ^enqueued_order_client_id, %Orders.Transitions.Fill{}}
    order = Orders.OrderRepo.get!(Orders.Order, enqueued_order_client_id)
    assert order.status == :filled
    assert order.cumulative_qty == Decimal.new("2")
    assert order.leaves_qty == Decimal.new("0")
    assert %DateTime{} = order.last_venue_timestamp
    assert %DateTime{} = order.last_received_at
  end

  test "logs a warning event when the order message has a nil clientId" do
    data = [build_venue_order(%{"clientId" => nil})]
    cast_order_msg(data, "update")

    assert_event(%Tai.Events.StreamMessageOrderUpdateUnhandled{}, :warn)
  end

  test "logs a warning event when the order message doesn't include require attributes" do
    data = [build_venue_order(%{})]
    cast_order_msg(data, "update")

    assert_event(%Tai.Events.StreamMessageOrderUpdateUnhandled{}, :warn)
  end

  defp cast_order_msg(data, type) do
    msg = %{
      "channel" => "orders",
      "type" => type,
      "data" => data
    }

    @venue
    |> ProcessAuth.process_name()
    |> GenServer.cast({msg, @received_at})
  end

  defp build_venue_order(attrs) do
    %{
      "clientId" => Ecto.UUID.generate(),
      "id" => 100,
      "createdAt" => "2020-12-25T03:00:00+00:00"
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
