defmodule Tai.Events.StreamDisconnect do
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type t :: %Tai.Events.StreamDisconnect{venue: venue_id, reason: term}

  @enforce_keys ~w(venue reason)a
  defstruct ~w(venue reason)a
end

defimpl Tai.LogEvent, for: Tai.Events.StreamDisconnect do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:reason, event.reason |> inspect)
  end
end
