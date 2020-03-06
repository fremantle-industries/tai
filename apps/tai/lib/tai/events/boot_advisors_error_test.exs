defmodule Tai.Events.BootAdvisorsTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms reason to a string" do
    event = %Tai.Events.BootAdvisorsError{
      reason: [venue_a: [accounts: [main: "Some error"]]]
    }

    assert TaiEvents.LogEvent.to_data(event) == %{
             reason: ~s([venue_a: [accounts: [main: "Some error"]]])
           }
  end
end
