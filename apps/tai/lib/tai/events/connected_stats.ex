defmodule Tai.Events.ConnectedStats do
  @type t :: %Tai.Events.ConnectedStats{
          venue_id: atom,
          received_at: DateTime.t(),
          bots: number,
          users: number
        }

  @enforce_keys [
    :venue_id,
    :received_at,
    :bots,
    :users
  ]
  defstruct [
    :venue_id,
    :received_at,
    :bots,
    :users
  ]
end
