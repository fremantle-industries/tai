defmodule Tai.Events.VenueBootError do
  alias Tai.Events.VenueBootError

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type t :: %VenueBootError{venue: venue_id, reason: term}

  @enforce_keys ~w(venue reason)a
  defstruct ~w(venue reason)a
end
