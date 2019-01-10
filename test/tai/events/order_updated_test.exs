defmodule Tai.Events.OrderUpdatedTest do
  use ExUnit.Case, async: true

  @base_attrs %{
    client_id: "my_client_id",
    venue_id: :my_venue,
    account_id: :my_account,
    product_symbol: :btc,
    side: :buy,
    type: :limit,
    time_in_force: :gtc,
    status: :open,
    price: Decimal.new("0.1"),
    qty: Decimal.new("0.2"),
    cumulative_qty: Decimal.new("0.3"),
    error_reason: :my_error_reason
  }

  test ".to_data/1 transforms decimal & datetime data to strings" do
    attrs = Map.merge(@base_attrs, %{venue_order_id: "abc123"})

    event = struct!(Tai.Events.OrderUpdated, attrs)

    assert %{} = json = Tai.LogEvent.to_data(event)
    assert json.client_id == "my_client_id"
    assert json.venue_id == :my_venue
    assert json.account_id == :my_account
    assert json.venue_order_id == "abc123"
    assert json.venue_created_at == nil
    assert json.product_symbol == :btc
    assert json.side == :buy
    assert json.type == :limit
    assert json.time_in_force == :gtc
    assert json.status == :open
    assert json.price == "0.1"
    assert json.qty == "0.2"
    assert json.cumulative_qty == "0.3"
    assert json.error_reason == :my_error_reason
  end

  test ".to_data/1 transforms the venue_created_at datetime data to a string" do
    {:ok, venue_created_at, _} = DateTime.from_iso8601("2015-01-23T23:50:07.123+00:00")
    attrs = Map.merge(@base_attrs, %{venue_created_at: venue_created_at})

    event = struct!(Tai.Events.OrderUpdated, attrs)

    assert %{} = json = Tai.LogEvent.to_data(event)
    assert json.venue_order_id == nil
    assert json.venue_created_at == "2015-01-23T23:50:07.123Z"
  end
end
