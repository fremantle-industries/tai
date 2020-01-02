defmodule Tai.Events.StreamAuthOk do
  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type t :: %Tai.Events.StreamAuthOk{venue: venue_id, credential: credential_id}

  @enforce_keys ~w(venue credential)a
  defstruct ~w(venue credential)a
end
