defmodule Tai.Events.StreamMessageUnhandled do
  @type t :: %Tai.Events.StreamMessageUnhandled{venue_id: atom, msg: map}

  @enforce_keys [:venue_id, :msg]
  defstruct [:venue_id, :msg]
end
