defmodule Tai.Orders.Transitions.AmendTest do
  use ExUnit.Case, async: false
  alias Tai.Orders.Transitions

  test ".attrs/1 returns a list of updatable order attributes" do
    price = Decimal.new(10)
    leaves_qty = Decimal.new("2.1")
    last_received_at = DateTime.utc_now()
    last_venue_timestamp = DateTime.utc_now()

    transition = %Transitions.Amend{
      price: price,
      leaves_qty: leaves_qty,
      last_received_at: last_received_at,
      last_venue_timestamp: last_venue_timestamp
    }

    attrs = Transitions.Amend.attrs(transition)
    assert length(attrs) == 4
    assert attrs[:price] == price
    assert attrs[:leaves_qty] == leaves_qty
    assert attrs[:last_received_at] == last_received_at
    assert attrs[:last_venue_timestamp] == last_venue_timestamp
  end
end
