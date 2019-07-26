defmodule Tai.Events.AdvisorHandleInsideQuoteInvalidReturn do
  @enforce_keys ~w(
    advisor_id
    group_id
    venue_id
    product_symbol
    return_value
  )a
  defstruct ~w(
    advisor_id
    group_id
    venue_id
    product_symbol
    return_value
  )a
end

defimpl Tai.LogEvent, for: Tai.Events.AdvisorHandleInsideQuoteInvalidReturn do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:return_value, event.return_value |> inspect)
  end
end
