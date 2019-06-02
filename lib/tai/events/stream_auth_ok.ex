defmodule Tai.Events.StreamAuthOk do
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type account_id :: Tai.Venues.Adapter.account_id()
  @type t :: %Tai.Events.StreamAuthOk{venue: venue_id, account: account_id}

  @enforce_keys ~w(venue account)a
  defstruct ~w(venue account)a
end
