defmodule TaiEventsTest do
  use ExUnit.Case, async: false

  defmodule MyEvent do
    defstruct []
  end

  defmodule MyOtherEvent do
    defstruct []
  end

  describe ".firehose_subscribe/0" do
    test "creates a registry entry for the :firehose topic" do
      start_supervised!({TaiEvents, 1})

      TaiEvents.firehose_subscribe()

      Registry.dispatch(TaiEvents, :firehose, fn entries ->
        for {pid, _} <- entries, do: send(pid, :firehose)
      end)

      assert_receive :firehose
    end
  end

  describe ".subscribe/1" do
    test "creates a registry entry for all events of the given type" do
      event = %MyEvent{}
      other_event = %MyOtherEvent{}
      start_supervised!({TaiEvents, 1})

      TaiEvents.subscribe(MyEvent)

      Registry.dispatch(TaiEvents, MyEvent, fn entries ->
        for {pid, _} <- entries, do: send(pid, event)
      end)

      Registry.dispatch(TaiEvents, MyOtherEvent, fn entries ->
        for {pid, _} <- entries, do: send(pid, other_event)
      end)

      assert_receive %MyEvent{}
      refute_receive %MyOtherEvent{}
    end
  end

  [:debug, :info, :warn, :error]
  |> Enum.each(fn level ->
    describe ".#{level}/1" do
      @level level

      test "sends the event to all subscribers of the event type" do
        level = @level
        event = %MyEvent{}
        other_event = %MyOtherEvent{}
        start_supervised!({TaiEvents, 1})

        Registry.register(TaiEvents, MyEvent, [])

        apply(TaiEvents, @level, [event])
        apply(TaiEvents, @level, [other_event])

        assert_receive {TaiEvents.Event, %MyEvent{}, ^level}
        refute_receive {TaiEvents.Event, %MyOtherEvent{}, ^level}
      end

      test "sends the event to firehose subscribers" do
        level = @level
        event = %MyEvent{}
        other_event = %MyOtherEvent{}
        start_supervised!({TaiEvents, 1})

        Registry.register(TaiEvents, :firehose, [])

        apply(TaiEvents, level, [event])
        apply(TaiEvents, level, [other_event])

        assert_receive {TaiEvents.Event, %MyEvent{}, ^level}
        assert_receive {TaiEvents.Event, %MyOtherEvent{}, ^level}
      end
    end
  end)
end
