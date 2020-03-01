defmodule Tai.Events.StreamDisconnectTest do
  use ExUnit.Case, async: true

  @base_attrs %{
    venue: :venue_a,
    reason: {:remote, :normal}
  }

  test ".to_data/1 transforms reason to a string" do
    event = struct!(Tai.Events.StreamDisconnect, @base_attrs)

    assert %{} = json = TaiEvents.LogEvent.to_data(event)
    assert json.venue == :venue_a
    assert json.reason == "{:remote, :normal}"
  end
end
