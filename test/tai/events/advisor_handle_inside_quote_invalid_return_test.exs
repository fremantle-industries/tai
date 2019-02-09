defmodule Tai.Events.AdvisorHandleInsideQuoteInvalidReturnTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms return_value to a string" do
    attrs = [return_value: {:some, :value}]
    event = struct(Tai.Events.AdvisorHandleInsideQuoteInvalidReturn, attrs)

    assert %{} = json = Tai.LogEvent.to_data(event)
    assert json.return_value == "{:some, :value}"
  end
end
