defmodule Tai.TimeFrame do
  require Logger

  defmacro debug(name, units \\ :micro_seconds, do: yield) do
    quote do
      start = :os.system_time(unquote(units))
      result = unquote(yield)
      time_passed = :os.system_time(unquote(units)) - start
      Logger.debug("#{unquote(name)} #{time_passed} #{unquote(units)}")

      result
    end
  end

  defmacro warn(name, units \\ :micro_seconds, do: yield) do
    quote do
      start = :os.system_time(unquote(units))
      result = unquote(yield)
      time_passed = :os.system_time(unquote(units)) - start
      Logger.warn("#{unquote(name)} #{time_passed} #{unquote(units)}")

      result
    end
  end

  defmacro info(name, units \\ :micro_seconds, do: yield) do
    quote do
      start = :os.system_time(unquote(units))
      result = unquote(yield)
      time_passed = :os.system_time(unquote(units)) - start
      Logger.info("#{unquote(name)} #{time_passed} #{unquote(units)}")

      result
    end
  end
end
