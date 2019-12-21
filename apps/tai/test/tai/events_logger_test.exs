defmodule Tai.EventsLoggerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  @event %Support.CustomEvent{hello: "world"}

  setup do
    start_supervised!({Tai.Events, 1})

    :ok
  end

  test "can start multiple loggers with different ids" do
    {:ok, _a} = Tai.EventsLogger.start_link(id: :a)
    {:ok, _b} = Tai.EventsLogger.start_link(id: :b)
  end

  test "logs error events" do
    {:ok, logger} = Tai.EventsLogger.start_link(id: __MODULE__)

    assert capture_log(fn ->
             send(logger, {Tai.Event, @event, :error})
             :timer.sleep(100)
           end) =~ "[error] {\"data\":{\"hello\":\"custom\"},\"type\":\"Support.CustomEvent\"}"
  end

  test "logs warn events" do
    {:ok, logger} = Tai.EventsLogger.start_link(id: __MODULE__)

    assert capture_log(fn ->
             send(logger, {Tai.Event, @event, :warn})
             :timer.sleep(100)
           end) =~ "[warn]  {\"data\":{\"hello\":\"custom\"},\"type\":\"Support.CustomEvent\"}"
  end

  test "logs info events" do
    {:ok, logger} = Tai.EventsLogger.start_link(id: __MODULE__)

    assert capture_log(fn ->
             send(logger, {Tai.Event, @event, :info})
             :timer.sleep(100)
           end) =~ "[info]  {\"data\":{\"hello\":\"custom\"},\"type\":\"Support.CustomEvent\"}"
  end

  test "logs debug events" do
    {:ok, logger} = Tai.EventsLogger.start_link(id: __MODULE__)

    assert capture_log(fn ->
             send(logger, {Tai.Event, @event, :debug})
             :timer.sleep(100)
           end) =~ "[debug] {\"data\":{\"hello\":\"custom\"},\"type\":\"Support.CustomEvent\"}"
  end
end
