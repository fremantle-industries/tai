defmodule Tai.Events.OrderUpdatedTest do
  use ExUnit.Case, async: true

  @base_attrs %{
    client_id: "my_client_id",
    venue_id: :my_venue,
    credential_id: :my_credential,
    product_symbol: :btc,
    product_type: :spot,
    side: :buy,
    type: :limit,
    time_in_force: :gtc,
    status: :open,
    price: Decimal.new("0.1"),
    qty: Decimal.new("0.2"),
    leaves_qty: Decimal.new("0.15"),
    cumulative_qty: Decimal.new("0.3"),
    error_reason: {:my_error_reason, "my msg"},
    close: true,
    enqueued_at: Timex.now()
  }

  test ".to_data/1 transforms decimal & error_reason data to strings" do
    attrs = Map.merge(@base_attrs, %{venue_order_id: "abc123"})

    event = struct!(Tai.Events.OrderUpdated, attrs)

    assert %{} = json = Tai.LogEvent.to_data(event)
    assert json.client_id == "my_client_id"
    assert json.venue_id == :my_venue
    assert json.credential_id == :my_credential
    assert json.venue_order_id == "abc123"
    assert json.last_received_at == nil
    assert json.product_symbol == :btc
    assert json.product_type == :spot
    assert json.side == :buy
    assert json.type == :limit
    assert json.time_in_force == :gtc
    assert json.status == :open
    assert json.price == "0.1"
    assert json.qty == "0.2"
    assert json.leaves_qty == "0.15"
    assert json.cumulative_qty == "0.3"
    assert json.error_reason == "{:my_error_reason, \"my msg\"}"
    assert json.close == true
  end

  test ".to_data/1 transforms datetime data to a string" do
    {:ok, enqueued_at, _} = DateTime.from_iso8601("2013-01-23T23:50:07.123+00:00")
    {:ok, last_received_at, _} = DateTime.from_iso8601("2014-01-23T23:50:07.123+00:00")
    {:ok, last_venue_timestamp, _} = DateTime.from_iso8601("2016-01-23T23:50:07.123+00:00")
    {:ok, updated_at, _} = DateTime.from_iso8601("2015-01-23T23:50:07.123+00:00")

    attrs =
      Map.merge(@base_attrs, %{
        enqueued_at: enqueued_at,
        updated_at: updated_at,
        last_received_at: last_received_at,
        last_venue_timestamp: last_venue_timestamp
      })

    event = struct!(Tai.Events.OrderUpdated, attrs)

    assert %{} = json = Tai.LogEvent.to_data(event)
    assert json.venue_order_id == nil
    assert json.enqueued_at == "2013-01-23T23:50:07.123Z"
    assert json.last_received_at == "2014-01-23T23:50:07.123Z"
    assert json.updated_at == "2015-01-23T23:50:07.123Z"
    assert json.last_venue_timestamp == "2016-01-23T23:50:07.123Z"
  end
end
