defmodule Tai.Events.LockAssetBalanceInsufficientFunds do
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type credential_id :: Tai.Venues.Adapter.credential_id()
  @type t :: %Tai.Events.LockAssetBalanceInsufficientFunds{
          venue_id: venue_id,
          credential_id: credential_id,
          asset: atom,
          free: Decimal.t(),
          min: Decimal.t(),
          max: Decimal.t()
        }

  @enforce_keys ~w(
    venue_id
    credential_id
    asset
    free
    min
    max
  )a
  defstruct ~w(
    venue_id
    credential_id
    asset
    free
    min
    max
  )a
end

defimpl Tai.LogEvent, for: Tai.Events.LockAssetBalanceInsufficientFunds do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:min, event.min |> Decimal.to_string(:normal))
    |> Map.put(:max, event.max |> Decimal.to_string(:normal))
    |> Map.put(:free, event.free |> Decimal.to_string(:normal))
  end
end
