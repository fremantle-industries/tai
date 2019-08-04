defmodule Tai.Events.StreamMessageUnhandled do
  @type t :: %Tai.Events.StreamMessageUnhandled{
          venue_id: atom,
          msg: map,
          received_at: DateTime.t()
        }

  @enforce_keys ~w(venue_id msg received_at)a
  defstruct ~w(venue_id msg received_at)a
end
