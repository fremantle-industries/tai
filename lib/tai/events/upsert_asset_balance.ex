defmodule Tai.Events.UpsertAssetBalance do
  @type t :: %Tai.Events.UpsertAssetBalance{
          venue_id: atom,
          account_id: atom,
          asset: atom,
          free: Decimal.t(),
          locked: Decimal.t()
        }

  @enforce_keys [:venue_id, :account_id, :asset, :free, :locked]
  defstruct [:venue_id, :account_id, :asset, :free, :locked]
end

defimpl Tai.LogEvent, for: Tai.Events.UpsertAssetBalance do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    free = event.free |> Decimal.to_string(:normal)
    locked = event.free |> Decimal.to_string(:normal)

    event
    |> Map.take(keys)
    |> Map.put(:free, free)
    |> Map.put(:locked, locked)
  end
end
