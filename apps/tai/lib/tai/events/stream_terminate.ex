defmodule Tai.Events.StreamTerminate do
  alias __MODULE__

  @type venue :: Tai.Venue.id()
  @type t :: %StreamTerminate{venue: venue, reason: term}

  @enforce_keys ~w(venue reason)a
  defstruct ~w(venue reason)a
end

defimpl TaiEvents.LogEvent, for: Tai.Events.StreamTerminate do
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
