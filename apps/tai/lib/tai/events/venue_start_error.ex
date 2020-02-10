defmodule Tai.Events.VenueStartError do
  alias __MODULE__

  @type venue_id :: Tai.Venue.id()
  @type t :: %VenueStartError{venue: venue_id, reason: term}

  @enforce_keys ~w(venue reason)a
  defstruct ~w(venue reason)a
end

defimpl TaiEvents.LogEvent, for: Tai.Events.VenueStartError do
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
