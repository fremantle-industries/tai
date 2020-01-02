defmodule Tai.Events.SubFreeAccount do
  alias __MODULE__

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type credential_id :: Tai.Venues.Adapter.credential_id()
  @type t :: %SubFreeAccount{
          venue_id: venue_id,
          credential_id: credential_id,
          asset: atom,
          val: Decimal.t(),
          free: Decimal.t(),
          locked: Decimal.t()
        }

  @enforce_keys ~w(
    venue_id
    credential_id
    asset
    val
    free
    locked
  )a
  defstruct ~w(
    venue_id
    credential_id
    asset
    val
    free
    locked
  )a
end

defimpl Tai.LogEvent, for: Tai.Events.SubFreeAccount do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:val, event.val |> Decimal.to_string(:normal))
    |> Map.put(:free, event.free |> Decimal.to_string(:normal))
    |> Map.put(:locked, event.locked |> Decimal.to_string(:normal))
  end
end
