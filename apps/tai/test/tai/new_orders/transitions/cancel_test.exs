defmodule Tai.NewOrders.Transitions.CancelTest do
  use ExUnit.Case, async: false
  alias Tai.NewOrders.Transitions

  test ".attrs/1 returns a list of updatable order attributes" do
    last_received_at = DateTime.utc_now()
    last_venue_timestamp = DateTime.utc_now()
    transition = %Transitions.Cancel{
      last_received_at: last_received_at,
      last_venue_timestamp: last_venue_timestamp
    }

    attrs = Transitions.Cancel.attrs(transition)
    assert length(attrs) == 3
    assert attrs[:leaves_qty] == Decimal.new(0)
    assert attrs[:last_received_at] == last_received_at
    assert attrs[:last_venue_timestamp] == last_venue_timestamp
  end
end
