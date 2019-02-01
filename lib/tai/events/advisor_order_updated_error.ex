defmodule Tai.Events.AdvisorOrderUpdatedError do
  @enforce_keys [:error, :stacktrace]
  defstruct [:error, :stacktrace]
end

defimpl Tai.LogEvent, for: Tai.Events.AdvisorOrderUpdatedError do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:error, event.error |> Scribe.format())
    |> Map.put(:stacktrace, event.stacktrace |> inspect)
  end
end
