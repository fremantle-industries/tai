defmodule Tai.Events.AdvisorOrderUpdatedError do
  @enforce_keys [:error, :stacktrace]
  defstruct [:error, :stacktrace]
end
