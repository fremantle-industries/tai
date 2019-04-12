defmodule Tai.EventsTest do
  use ExUnit.Case, async: false

  defmodule MyEvent do
    defstruct []
  end

  defmodule MyOtherEvent do
    defstruct []
  end

  describe ".firehose_subscribe/0" do
    test "creates a registry entry for the :firehose topic" do
      start_supervised!({Tai.Events, 1})

      Tai.Events.firehose_subscribe()

      Registry.dispatch(Tai.Events, :firehose, fn entries ->
        for {pid, _} <- entries, do: send(pid, :firehose)
      end)

      assert_receive :firehose
    end
  end

  describe ".subscribe/1" do
    test "creates a registry entry for all events of the given type" do
      event = %MyEvent{}
      other_event = %MyOtherEvent{}
      start_supervised!({Tai.Events, 1})

      Tai.Events.subscribe(MyEvent)

      Registry.dispatch(Tai.Events, MyEvent, fn entries ->
        for {pid, _} <- entries, do: send(pid, event)
      end)

      Registry.dispatch(Tai.Events, MyOtherEvent, fn entries ->
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
        start_supervised!({Tai.Events, 1})

        Registry.register(Tai.Events, MyEvent, [])

        apply(Tai.Events, @level, [event])
        apply(Tai.Events, @level, [other_event])

        assert_receive {Tai.Event, %MyEvent{}, ^level}
        refute_receive {Tai.Event, %MyOtherEvent{}, ^level}
      end

      test "sends the event to firehose subscribers" do
        level = @level
        event = %MyEvent{}
        other_event = %MyOtherEvent{}
        start_supervised!({Tai.Events, 1})

        Registry.register(Tai.Events, :firehose, [])

        apply(Tai.Events, level, [event])
        apply(Tai.Events, level, [other_event])

        assert_receive {Tai.Event, %MyEvent{}, ^level}
        assert_receive {Tai.Event, %MyOtherEvent{}, ^level}
      end
    end
  end)
end
