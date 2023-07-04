defmodule Tai.EventsLoggerTest do
  use Tai.TestSupport.DataCase, async: false
  import ExUnit.CaptureLog

  @event %Support.CustomEvent{hello: "world"}

  test "can start multiple loggers with different ids" do
    {:ok, a} = Tai.EventsLogger.start_link(id: :a)
    {:ok, b} = Tai.EventsLogger.start_link(id: :b)
    :ok = GenServer.stop(a)
    :ok = GenServer.stop(b)
  end

  test "logs error events" do
    logger = start_supervised!({Tai.EventsLogger, id: __MODULE__})

    assert capture_log(fn ->
             send(logger, {TaiEvents.Event, @event, :error})
             :timer.sleep(100)
           end) =~ "[error] {\"data\":{\"hello\":\"custom\"},\"type\":\"Support.CustomEvent\"}"
  end

  test "logs warning events" do
    logger = start_supervised!({Tai.EventsLogger, id: __MODULE__})

    log = capture_log(fn ->
             send(logger, {TaiEvents.Event, @event, :warning})
             :timer.sleep(100)
    end)

    assert log =~ "[warn"
    assert log =~ "{\"data\":{\"hello\":\"custom\"},\"type\":\"Support.CustomEvent\"}"
  end

  test "logs info events" do
    logger = start_supervised!({Tai.EventsLogger, id: __MODULE__})

    log = capture_log(fn ->
             send(logger, {TaiEvents.Event, @event, :info})
             :timer.sleep(100)
           end)
    assert log =~ "[info"
    assert log =~ "{\"data\":{\"hello\":\"custom\"},\"type\":\"Support.CustomEvent\"}"
  end

  test "logs debug events" do
    logger = start_supervised!({Tai.EventsLogger, id: __MODULE__})

    assert capture_log(fn ->
             send(logger, {TaiEvents.Event, @event, :debug})
             :timer.sleep(100)
           end) =~ "[debug] {\"data\":{\"hello\":\"custom\"},\"type\":\"Support.CustomEvent\"}"
  end

  test "logs with custom logger" do
    defmodule CustomLogger do
      require Logger

      def log(level, _event) do
        Logger.log(level, "message from custom logger")
      end
    end

    logger = start_supervised!({Tai.EventsLogger, id: __MODULE__, logger: CustomLogger})

    log = capture_log(fn ->
             send(logger, {TaiEvents.Event, @event, :info})
             :timer.sleep(100)
           end)
    assert log  =~ "[info"
    assert log  =~ "message from custom logger"
  end
end
