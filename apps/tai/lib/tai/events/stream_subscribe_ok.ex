defmodule Tai.Events.StreamSubscribeOk do
  alias __MODULE__

  @type venue :: Tai.Venue.id()
  @type t :: %StreamSubscribeOk{
          venue: venue,
          channel_name: String.t(),
          received_at: DateTime.t(),
          meta: map,
        }

  @enforce_keys ~w[venue channel_name received_at meta]a
  defstruct ~w[venue channel_name received_at meta]a
end
