defmodule Tai.Orders.Transitions.AcceptCreateTest do
  use ExUnit.Case, async: false
  alias Tai.Orders.Transitions

  test ".attrs/1 returns a list of updatable order attributes" do
    last_received_at = DateTime.utc_now()
    last_venue_timestamp = DateTime.utc_now()
    venue_order_id = "abc123"

    transition = %Transitions.AcceptCreate{
      venue_order_id: "abc123",
      last_received_at: last_received_at,
      last_venue_timestamp: last_venue_timestamp
    }

    attrs = Transitions.AcceptCreate.attrs(transition)
    assert length(attrs) == 3
    assert attrs[:venue_order_id] == venue_order_id
    assert attrs[:last_received_at] == last_received_at
    assert attrs[:last_venue_timestamp] == last_venue_timestamp
  end
end
