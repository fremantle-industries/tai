defmodule Tai.Orders.Transitions.AcceptAmendTest do
  use ExUnit.Case, async: false
  alias Tai.Orders.Transitions

  test ".attrs/1 returns a list of updatable order attributes" do
    last_received_at = DateTime.utc_now()
    last_venue_timestamp = DateTime.utc_now()

    transition = %Transitions.AcceptAmend{
      last_received_at: last_received_at,
      last_venue_timestamp: last_venue_timestamp
    }

    attrs = Transitions.AcceptAmend.attrs(transition)
    assert length(attrs) == 2
    assert attrs[:last_received_at] == last_received_at
    assert attrs[:last_venue_timestamp] == last_venue_timestamp
  end
end
