defmodule Tai.Events.AdvisorHandleInsideQuoteError do
  @enforce_keys ~w(
    advisor_id
    group_id
    venue_id
    product_symbol
    error
    stacktrace
  )a
  defstruct ~w(
    advisor_id
    group_id
    venue_id
    product_symbol
    error
    stacktrace
  )a
end

defimpl Tai.LogEvent, for: Tai.Events.AdvisorHandleInsideQuoteError do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:error, event.error |> inspect)
    |> Map.put(:stacktrace, event.stacktrace |> inspect)
  end
end
