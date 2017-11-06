defmodule Tai.Events.StreamConnectionOk do
  @type t :: %Tai.Events.StreamConnectionOk{
          venue_id: atom
        }

  @enforce_keys [:venue_id]
  defstruct [:venue_id]
end
