defmodule Tai.VenueAdapters.OkEx.Stream.ProcessAuth.OrderTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Assertions.Event
  alias Tai.VenueAdapters.OkEx.Stream.ProcessAuth
  alias Tai.VenueAdapters.OkEx.ClientId


  @received_at Tai.Time.monotonic_time()

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai_events)
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tzdata)
    {:ok, _} = Application.ensure_all_started(:tai)
    start_supervised!({ProcessAuth, [venue: :my_venue]})
    :ok
  end

  test "broadcasts an event when the order can't be found" do
    TaiEvents.firehose_subscribe()
    accept_create_client_id = Ecto.UUID.generate()
    open_client_id = Ecto.UUID.generate()
    canceled_client_id = Ecto.UUID.generate()
    partially_filled_client_id = Ecto.UUID.generate()
    filled_client_id = Ecto.UUID.generate()

    venue_orders = [
      %{
        "client_oid" => accept_create_client_id |> ClientId.to_venue(),
        "order_id" => "submittingOrderA",
        "state" => "3",
        "timestamp" => "2019-01-05T02:03:06.309Z"
      },
      %{
        "client_oid" => open_client_id |> ClientId.to_venue(),
        "order_id" => "pendingOrderA",
        "state" => "0",
        "filled_qty" => "2",
        "size" => "10",
        "timestamp" => "2019-01-09T02:03:06.309Z"
      },
      %{
        "client_oid" => canceled_client_id |> ClientId.to_venue(),
        "state" => "-1",
        "timestamp" => "2019-01-11T02:03:06.309Z"
      },
      %{
        "client_oid" => partially_filled_client_id |> ClientId.to_venue(),
        "state" => "1",
        "size" => 3,
        "filled_qty" => 10,
        "timestamp" => "2018-12-27T05:33:50.832Z"
      },
      %{
        "client_oid" => filled_client_id |> ClientId.to_venue(),
        "state" => "2",
        "filled_qty" => "5",
        "timestamp" => "2018-12-27T05:33:50.795Z"
      }
    ]

    :my_venue
    |> ProcessAuth.to_name()
    |> GenServer.cast({%{"table" => "futures/order", "data" => venue_orders}, @received_at})

    assert_event(
      %Tai.Events.OrderUpdateNotFound{
        action: Tai.Trading.OrderStore.Actions.AcceptCreate
      } = accept_create_not_found_event
    )

    assert accept_create_not_found_event.client_id == accept_create_client_id

    assert_event(
      %Tai.Events.OrderUpdateNotFound{
        action: Tai.Trading.OrderStore.Actions.Open
      } = open_not_found_event
    )

    assert open_not_found_event.client_id == open_client_id

    assert_event(
      %Tai.Events.OrderUpdateNotFound{
        action: Tai.Trading.OrderStore.Actions.PassiveCancel
      } = canceled_not_found_event
    )

    assert canceled_not_found_event.client_id == canceled_client_id

    assert_event(
      %Tai.Events.OrderUpdateNotFound{
        action: Tai.Trading.OrderStore.Actions.PassivePartialFill
      } = partially_filled_not_found_event
    )

    assert partially_filled_not_found_event.client_id == partially_filled_client_id

    assert_event(
      %Tai.Events.OrderUpdateNotFound{
        action: Tai.Trading.OrderStore.Actions.PassiveFill
      } = filled_not_found_event
    )

    assert filled_not_found_event.client_id == filled_client_id
  end

  test "emits a warning when the venue message can't be handled" do
    TaiEvents.firehose_subscribe()

    :my_venue
    |> ProcessAuth.to_name()
    |> GenServer.cast(
      {%{"table" => "order", "action" => "update", "data" => [%{"unhandled" => true}]},
       @received_at}
    )

    assert_event(%Tai.Events.StreamMessageUnhandled{}, :warn)
  end

  test "emits a warning when the order message can't be handled" do
    TaiEvents.firehose_subscribe()
    client_id = Ecto.UUID.generate()

    venue_orders = [
      %{
        "client_oid" => client_id |> ClientId.to_venue(),
        "order_id" => "submittingOrderA",
        "state" => "invalid status",
        "timestamp" => "2019-01-05T02:03:06.309Z"
      }
    ]

    :my_venue
    |> ProcessAuth.to_name()
    |> GenServer.cast({%{"table" => "futures/order", "data" => venue_orders}, @received_at})

    assert_event(%Tai.Events.StreamMessageUnhandled{}, :warn)
  end
end
