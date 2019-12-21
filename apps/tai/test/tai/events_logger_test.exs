defmodule Tai.EventsLoggerTest do
  use ExUnit.Case, async: true

  setup do
    start_supervised!({Tai.Events, 1})

    :ok
  end

  test "can start multiple loggers with different ids" do
    {:ok, _a} = Tai.EventsLogger.start_link(id: :a)
    {:ok, _b} = Tai.EventsLogger.start_link(id: :b)
  end
end
