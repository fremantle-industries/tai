defmodule Tai.Events.AdvisorHandleEventInvalidReturnTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms event & return_value to a string" do
    attrs = [event: {:some, :event}, return_value: {:some, :return}]
    event = struct(Tai.Events.AdvisorHandleEventInvalidReturn, attrs)

    assert %{} = json = TaiEvents.LogEvent.to_data(event)
    assert json.event == "{:some, :event}"
    assert json.return_value == "{:some, :return}"
  end
end
