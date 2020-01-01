defmodule Tai.Events.StreamConnect do
  @type venue_id :: Tai.Venue.id()
  @type t :: %Tai.Events.StreamConnect{venue: venue_id}

  @enforce_keys ~w(venue)a
  defstruct ~w(venue)a
end
