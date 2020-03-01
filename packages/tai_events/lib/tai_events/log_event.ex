defprotocol TaiEvents.LogEvent do
  @fallback_to_any true
  def to_data(event)
end

defimpl TaiEvents.LogEvent, for: Any do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    Map.take(event, keys)
  end
end
