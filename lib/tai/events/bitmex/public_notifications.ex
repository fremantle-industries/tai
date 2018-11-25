defmodule Tai.Events.Bitmex.PublicNotifications do
  @type t :: %Tai.Events.Bitmex.PublicNotifications{
          venue_id: atom,
          action: String.t(),
          data: list
        }

  @enforce_keys [:venue_id, :data, :action]
  defstruct [:venue_id, :data, :action]
end
