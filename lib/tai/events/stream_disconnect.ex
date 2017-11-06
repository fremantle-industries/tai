defmodule Tai.Events.StreamDisconnect do
  @type t :: %Tai.Events.StreamDisconnect{venue_id: atom, reason: term}

  @enforce_keys [:venue_id, :reason]
  defstruct [:venue_id, :reason]
end
