defprotocol Tai.LogEvent do
  @fallback_to_any true
  def to_data(event)
end

defimpl Tai.LogEvent, for: Any do
  def to_data(event), do: event |> extract

  defp extract(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event |> Map.take(keys)
  end
end
