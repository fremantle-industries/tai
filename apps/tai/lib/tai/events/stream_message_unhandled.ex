defmodule Tai.Events.StreamMessageUnhandled do
  alias __MODULE__

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type t :: %StreamMessageUnhandled{
          venue_id: venue_id,
          msg: map,
          received_at: DateTime.t()
        }

  @enforce_keys ~w(venue_id msg received_at)a
  defstruct ~w(venue_id msg received_at)a
end
