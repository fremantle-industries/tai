defmodule Tai.Events.AdvisorHandleMarketQuoteErrorTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms error & stacktrace to a string" do
    attrs = [
      event: {:event, :some_event},
      error: %RuntimeError{message: "!!!This is an ERROR!!!"},
      stacktrace: [
        {MyAdvisor, :execute_handle_market_quote, 2, [file: 'lib/tai/advisor.ex', line: 226]}
      ]
    ]

    event = struct(Tai.Events.AdvisorHandleMarketQuoteError, attrs)

    assert %{} = json = TaiEvents.LogEvent.to_data(event)
    assert json.event == "{:event, :some_event}"
    assert json.error == "%RuntimeError{message: \"!!!This is an ERROR!!!\"}"

    assert json.stacktrace ==
             inspect([{MyAdvisor, :execute_handle_market_quote, 2, [file: 'lib/tai/advisor.ex', line: 226]}])
  end
end
