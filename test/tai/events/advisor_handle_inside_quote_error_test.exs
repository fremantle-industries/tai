defmodule Tai.Events.AdvisorHandleInsideQuoteErrorTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms error & stacktrace to a string" do
    attrs = [
      error: %RuntimeError{message: "!!!This is an ERROR!!!"},
      stacktrace: [
        {MyAdvisor, :execute_handle_inside_quote, 5, [file: 'lib/tai/advisor.ex', line: 226]}
      ]
    ]

    event = struct(Tai.Events.AdvisorHandleInsideQuoteError, attrs)

    assert %{} = json = Tai.LogEvent.to_data(event)
    assert json.error == "%RuntimeError{message: \"!!!This is an ERROR!!!\"}"

    assert json.stacktrace ==
             "[{MyAdvisor, :execute_handle_inside_quote, 5, [file: 'lib/tai/advisor.ex', line: 226]}]"
  end
end
