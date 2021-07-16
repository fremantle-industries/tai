defmodule Tai.Orders.Transitions.OpenTest do
  use ExUnit.Case, async: false
  alias Tai.Orders.Transitions

  test ".attrs/1 returns a list of updatable order attributes" do
    venue_order_id = "abc123"
    cumulative_qty = Decimal.new("2.1")
    leaves_qty = Decimal.new("1.1")
    last_received_at = DateTime.utc_now()
    last_venue_timestamp = DateTime.utc_now()

    transition = %Transitions.Open{
      venue_order_id: venue_order_id,
      cumulative_qty: cumulative_qty,
      leaves_qty: leaves_qty,
      last_received_at: last_received_at,
      last_venue_timestamp: last_venue_timestamp
    }

    attrs = Transitions.Open.attrs(transition)
    assert length(attrs) == 6
    assert attrs[:venue_order_id] == venue_order_id
    assert attrs[:cumulative_qty] == cumulative_qty
    assert attrs[:leaves_qty] == leaves_qty
    assert attrs[:qty] == Decimal.new("3.2")
    assert attrs[:last_received_at] == last_received_at
    assert attrs[:last_venue_timestamp] == last_venue_timestamp
  end
end
