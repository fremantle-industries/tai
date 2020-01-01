defmodule Tai.Events.StreamError do
  alias __MODULE__

  @type venue_id :: Tai.Venue.id()
  @type t :: %StreamError{
          venue_id: venue_id,
          reason: term
        }

  @enforce_keys ~w(venue_id reason)a
  defstruct ~w(venue_id reason)a
end

defimpl Tai.LogEvent, for: Tai.Events.StreamError do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:reason, event.reason |> inspect)
  end
end
