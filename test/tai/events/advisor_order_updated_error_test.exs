defmodule Tai.Events.AdvisorOrderUpdatedErrorTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms the error and stacktrace to string" do
    attrs = %{
      error: %BadArityError{args: :foo},
      stacktrace: [
        {Strategies.FuturesCalendarSpreadVolatility.Advisor, :handle_cast, 2,
         [file: 'lib/tai/advisor.ex', line: 149]}
      ]
    }

    event = struct!(Tai.Events.AdvisorOrderUpdatedError, attrs)

    assert %{} = json = Tai.LogEvent.to_data(event)
    assert json.error == "%BadArityError{args: :foo, function: nil}"

    assert json.stacktrace ==
             "[{Strategies.FuturesCalendarSpreadVolatility.Advisor, :handle_cast, 2, [file: 'lib/tai/advisor.ex', line: 149]}]"
  end
end
