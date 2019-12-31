defmodule Tai.Events.UpsertAssetBalance do
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type credential_id :: Tai.Venues.Adapter.credential_id()
  @type t :: %Tai.Events.UpsertAssetBalance{
          venue_id: venue_id,
          credential_id: credential_id,
          asset: atom,
          free: Decimal.t(),
          locked: Decimal.t()
        }

  @enforce_keys ~w(venue_id credential_id asset free locked)a
  defstruct ~w(venue_id credential_id asset free locked)a
end

defimpl Tai.LogEvent, for: Tai.Events.UpsertAssetBalance do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:free, event.free && event.free |> Decimal.to_string(:normal))
    |> Map.put(:locked, event.locked && event.locked |> Decimal.to_string(:normal))
  end
end
