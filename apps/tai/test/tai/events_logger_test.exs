defmodule Tai.EventsLoggerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  @event %Support.CustomEvent{hello: "world"}

  setup do
    start_supervised!({Tai.Events, 1})

    :ok
  end

  test "can start multiple loggers with different ids" do
    {:ok, a} = Tai.EventsLogger.start_link(id: :a)
    {:ok, b} = Tai.EventsLogger.start_link(id: :b)
    :ok = GenServer.stop(a)
    :ok = GenServer.stop(b)
  end

  test "logs error events" do
    logger = start_supervised!({Tai.EventsLogger, id: __MODULE__})

    assert capture_log(fn ->
             send(logger, {Tai.Event, @event, :error})
             :timer.sleep(100)
           end) =~ "[error] {\"data\":{\"hello\":\"custom\"},\"type\":\"Support.CustomEvent\"}"
  end

  test "logs warn events" do
    logger = start_supervised!({Tai.EventsLogger, id: __MODULE__})

    assert capture_log(fn ->
             send(logger, {Tai.Event, @event, :warn})
             :timer.sleep(100)
           end) =~ "[warn]  {\"data\":{\"hello\":\"custom\"},\"type\":\"Support.CustomEvent\"}"
  end

  test "logs info events" do
    logger = start_supervised!({Tai.EventsLogger, id: __MODULE__})

    assert capture_log(fn ->
             send(logger, {Tai.Event, @event, :info})
             :timer.sleep(100)
           end) =~ "[info]  {\"data\":{\"hello\":\"custom\"},\"type\":\"Support.CustomEvent\"}"
  end

  test "logs debug events" do
    logger = start_supervised!({Tai.EventsLogger, id: __MODULE__})

    assert capture_log(fn ->
             send(logger, {Tai.Event, @event, :debug})
             :timer.sleep(100)
           end) =~ "[debug] {\"data\":{\"hello\":\"custom\"},\"type\":\"Support.CustomEvent\"}"
  end
end
