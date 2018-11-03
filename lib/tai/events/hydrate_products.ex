defmodule Tai.Events.HydrateProducts do
  @type t :: %Tai.Events.HydrateProducts{
          venue_id: atom,
          total: non_neg_integer,
          filtered: non_neg_integer
        }

  @enforce_keys [:venue_id, :total, :filtered]
  defstruct [:venue_id, :total, :filtered]
end
