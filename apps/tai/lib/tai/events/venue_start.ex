defmodule Tai.Events.VenueStart do
  alias __MODULE__

  @type venue_id :: Tai.Venue.id()
  @type t :: %VenueStart{venue: venue_id}

  @enforce_keys ~w(venue)a
  defstruct ~w(venue)a
end
