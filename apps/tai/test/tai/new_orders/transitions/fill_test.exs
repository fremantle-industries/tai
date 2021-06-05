defmodule Tai.NewOrders.Transitions.FillTest do
  use ExUnit.Case, async: false
  alias Tai.NewOrders.Transitions

  test ".attrs/1 returns a list of updatable order attributes" do
    venue_order_id = "abc123"
    cumulative_qty = Decimal.new("2.1")
    last_received_at = DateTime.utc_now()
    last_venue_timestamp = DateTime.utc_now()
    transition = %Transitions.Fill{
      venue_order_id: venue_order_id,
      cumulative_qty: cumulative_qty,
      last_received_at: last_received_at,
      last_venue_timestamp: last_venue_timestamp
    }

    attrs = Transitions.Fill.attrs(transition)
    assert length(attrs) == 5
    assert attrs[:venue_order_id] == venue_order_id
    assert attrs[:cumulative_qty] == cumulative_qty
    assert attrs[:leaves_qty] == Decimal.new(0)
    assert attrs[:last_received_at] == last_received_at
    assert attrs[:last_venue_timestamp] == last_venue_timestamp
  end
end
