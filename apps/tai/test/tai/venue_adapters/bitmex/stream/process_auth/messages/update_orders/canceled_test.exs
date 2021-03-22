defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.CanceledTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Assertions.Event
  alias Tai.VenueAdapters.Bitmex.ClientId
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth
  alias Tai.Trading.OrderStore

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tzdata)
    end)

    {:ok, _} = Application.ensure_all_started(:tzdata)
    start_supervised!({TaiEvents, 1})
    start_supervised!(Tai.Trading.OrderStore)

    :ok
  end

  @venue_client_id "gtc-TCRG7aPSQsmj1Z8jXfbovg=="
  @received_at Tai.Time.monotonic_time()
  @timestamp "2019-09-07T06:00:04.808Z"
  @state struct(ProcessAuth.State)

  test ".process/3 passively cancels the order" do
    TaiEvents.firehose_subscribe()

    assert {:ok, order} = enqueue()

    action = struct(Tai.Trading.OrderStore.Actions.Reject, client_id: order.client_id, last_received_at: Tai.Time.monotonic_time())
    assert {:ok, {_old, _updated}} = OrderStore.update(action)

    msg =
      struct(ProcessAuth.Messages.UpdateOrders.Canceled,
        cl_ord_id: order.client_id |> ClientId.to_venue(:gtc),
        timestamp: @timestamp
      )

    ProcessAuth.Message.process(msg, @received_at, @state)

    assert_event(%Tai.Events.OrderUpdated{status: :canceled} = canceled_event)
    assert canceled_event.venue_id == :my_venue
    assert canceled_event.leaves_qty == Decimal.new(0)
    assert canceled_event.qty == Decimal.new("1.1")
    assert %DateTime{} = canceled_event.last_received_at
    assert %DateTime{} = canceled_event.last_venue_timestamp
  end

  test ".process/3 broadcasts an invalid status warning" do
    TaiEvents.firehose_subscribe()

    assert {:ok, order} = enqueue()

    action = struct(Tai.Trading.OrderStore.Actions.Skip, client_id: order.client_id)
    assert {:ok, {_old, _updated}} = OrderStore.update(action)

    msg =
      struct(ProcessAuth.Messages.UpdateOrders.Canceled,
        cl_ord_id: order.client_id |> ClientId.to_venue(:gtc),
        timestamp: @timestamp
      )

    ProcessAuth.Message.process(msg, @received_at, @state)

    assert_event(%Tai.Events.OrderUpdateInvalidStatus{} = invalid_status_event)
    assert invalid_status_event.action == Tai.Trading.OrderStore.Actions.PassiveCancel
    assert invalid_status_event.last_received_at != nil
    assert %DateTime{} = invalid_status_event.last_venue_timestamp
    assert invalid_status_event.was == :skip

    assert invalid_status_event.required == [
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

  test ".process/3 broadcasts a not found warning" do
    TaiEvents.firehose_subscribe()

    msg =
      struct(ProcessAuth.Messages.UpdateOrders.Canceled,
        cl_ord_id: @venue_client_id,
        timestamp: @timestamp
      )

    ProcessAuth.Message.process(msg, @received_at, @state)

    assert_event(%Tai.Events.OrderUpdateNotFound{} = not_found_event)
    assert not_found_event.client_id != @venue_client_id
    assert not_found_event.action == Tai.Trading.OrderStore.Actions.PassiveCancel
  end

  defp enqueue, do: build_submission() |> OrderStore.enqueue()

  defp build_submission do
    struct(Tai.Trading.OrderSubmissions.BuyLimitGtc,
      venue_id: :my_venue,
      product_symbol: :btc_usd,
      price: Decimal.new("100.1"),
      qty: Decimal.new("1.1")
    )
  end
end
