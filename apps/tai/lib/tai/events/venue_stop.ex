defmodule Tai.Events.VenueStop do
  alias __MODULE__

  @type venue_id :: Tai.Venue.id()
  @type t :: %VenueStop{venue: venue_id}

  @enforce_keys ~w(venue)a
  defstruct ~w(venue)a
end
