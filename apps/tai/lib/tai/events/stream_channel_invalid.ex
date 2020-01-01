defmodule Tai.Events.StreamChannelInvalid do
  @type venue_id :: Tai.Venue.id()
  @type t :: %Tai.Events.StreamChannelInvalid{
          venue: venue_id,
          name: atom,
          available: [atom]
        }

  @enforce_keys ~w(venue name available)a
  defstruct ~w(venue name available)a
end

defimpl Tai.LogEvent, for: Tai.Events.StreamChannelInvalid do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:available, event.available |> inspect())
  end
end
