defmodule Tai.Events.StreamErrorTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms reason to a string" do
    event = %Tai.Events.StreamError{
      venue_id: :my_venue,
      reason: {:function_clause, "Some error"}
    }

    assert Tai.LogEvent.to_data(event) == %{
             venue_id: :my_venue,
             reason: ~s({:function_clause, "Some error"})
           }
  end
end
