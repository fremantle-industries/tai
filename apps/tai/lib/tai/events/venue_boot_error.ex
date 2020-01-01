defmodule Tai.Events.VenueBootError do
  alias Tai.Events.VenueBootError

  @type venue_id :: Tai.Venue.id()
  @type t :: %VenueBootError{venue: venue_id, reason: term}

  @enforce_keys ~w(venue reason)a
  defstruct ~w(venue reason)a
end

defimpl Tai.LogEvent, for: Tai.Events.VenueBootError do
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
