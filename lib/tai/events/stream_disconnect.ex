defmodule Tai.Events.StreamDisconnect do
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type t :: %Tai.Events.StreamDisconnect{venue: venue_id, reason: term}

  @enforce_keys ~w(venue reason)a
  defstruct ~w(venue reason)a
end
