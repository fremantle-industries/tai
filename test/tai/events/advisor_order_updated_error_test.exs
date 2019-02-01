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

    assert json.error ==
             "\e[39m+------------------+-----------------+---------+-------------+\n|\e[36m :__exception__   \e[0m|\e[36m :__struct__     \e[0m|\e[36m :args   \e[0m|\e[36m :function   \e[0m|\n+------------------+-----------------+---------+-------------+\n|\e[35m true             \e[0m|\e[36m BadArityError   \e[0m|\e[36m :foo    \e[0m|\e[35m nil         \e[0m|\n+------------------+-----------------+---------+-------------+\n"

    assert json.stacktrace ==
             "[{Strategies.FuturesCalendarSpreadVolatility.Advisor, :handle_cast, 2, [file: 'lib/tai/advisor.ex', line: 149]}]"
  end
end
