defprotocol Tai.LogEvent do
  @fallback_to_any true
  def to_data(event)
end

defimpl Tai.LogEvent, for: Any do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    Map.take(event, keys)
  end
end
