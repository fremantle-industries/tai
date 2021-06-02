defmodule Tai.Events.StreamMessageInvalidOrderClientId do
  alias __MODULE__

  @type t :: %StreamMessageInvalidOrderClientId{
          venue_id: Tai.Venue.id(),
          client_id: String.t(),
          received_at: DateTime.t()
        }

  @enforce_keys ~w[venue_id client_id received_at]a
  defstruct ~w[venue_id client_id received_at]a
end
