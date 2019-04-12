defmodule Tai.Events.VenueBoot do
  alias Tai.Events.VenueBoot

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type t :: %VenueBoot{venue: venue_id}

  @enforce_keys ~w(venue)a
  defstruct ~w(venue)a
end
