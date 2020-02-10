defmodule Tai.TestSupport.Assertions.Event do
  defmacro assert_event(event) do
    quote do
      assert_receive {TaiEvents.Event, unquote(event), _}
    end
  end

  defmacro assert_event(event, level) do
    quote do
      assert_receive {TaiEvents.Event, unquote(event), unquote(level)}
    end
  end

  defmacro assert_event(event, level, timeout) do
    quote do
      assert_receive {TaiEvents.Event, unquote(event), unquote(level)}, unquote(timeout)
    end
  end

  defmacro refute_event(event) do
    quote do
      refute_receive {TaiEvents.Event, unquote(event), _}
    end
  end

  defmacro refute_event(event, level) do
    quote do
      refute_receive {TaiEvents.Event, unquote(event), unquote(level)}
    end
  end

  defmacro refute_event(event, level, timeout) do
    quote do
      refute_receive {TaiEvents.Event, unquote(event), unquote(level)}, unquote(timeout)
    end
  end
end
