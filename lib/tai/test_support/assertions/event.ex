defmodule Tai.TestSupport.Assertions.Event do
  defmacro assert_event(event) do
    quote do
      assert_receive {Tai.Event, unquote(event), _}
    end
  end

  defmacro refute_event(event) do
    quote do
      refute_receive {Tai.Event, unquote(event), _}
    end
  end
end
