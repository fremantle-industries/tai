defmodule Tai.Events.VenueStartErrorTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms reason to a string" do
    event = %Tai.Events.VenueStartError{
      venue: :my_venue,
      reason: [accounts: :mock_not_found]
    }

    assert TaiEvents.LogEvent.to_data(event) == %{
             venue: :my_venue,
             reason: "[accounts: :mock_not_found]"
           }
  end
end
