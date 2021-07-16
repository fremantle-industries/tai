defmodule Tai.Orders.Transitions.RejectTest do
  use ExUnit.Case, async: false
  alias Tai.Orders.Transitions

  test ".attrs/1 returns a list of updatable order attributes" do
    venue_order_id = "abc123"
    last_received_at = DateTime.utc_now()
    last_venue_timestamp = DateTime.utc_now()

    transition = %Transitions.Reject{
      venue_order_id: venue_order_id,
      last_received_at: last_received_at,
      last_venue_timestamp: last_venue_timestamp
    }

    attrs = Transitions.Reject.attrs(transition)
    assert length(attrs) == 4
    assert attrs[:venue_order_id] == venue_order_id
    assert attrs[:leaves_qty] == Decimal.new(0)
    assert attrs[:last_received_at] == last_received_at
    assert attrs[:last_venue_timestamp] == last_venue_timestamp
  end
end
