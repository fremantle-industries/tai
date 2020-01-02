defmodule Tai.Events.VenueBoot do
  alias __MODULE__

  @type venue_id :: Tai.Venue.id()
  @type t :: %VenueBoot{venue: venue_id}

  @enforce_keys ~w(venue)a
  defstruct ~w(venue)a
end
