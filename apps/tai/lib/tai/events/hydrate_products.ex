defmodule Tai.Events.HydrateProducts do
  alias __MODULE__

  @type venue_id :: Tai.Venue.id()
  @type t :: %HydrateProducts{
          venue_id: venue_id,
          total: non_neg_integer,
          filtered: non_neg_integer
        }

  @enforce_keys ~w(venue_id total filtered)a
  defstruct ~w(venue_id total filtered)a
end
