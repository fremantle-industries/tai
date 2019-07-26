defmodule Tai.Events.LockAssetBalanceOk do
  @type t :: %Tai.Events.LockAssetBalanceOk{
          venue_id: atom,
          account_id: atom,
          asset: atom,
          qty: Decimal.t(),
          min: Decimal.t(),
          max: Decimal.t()
        }

  @enforce_keys [
    :venue_id,
    :account_id,
    :asset,
    :qty,
    :min,
    :max
  ]
  defstruct [
    :venue_id,
    :account_id,
    :asset,
    :qty,
    :min,
    :max
  ]
end

defimpl Tai.LogEvent, for: Tai.Events.LockAssetBalanceOk do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:min, event.min |> Decimal.to_string(:normal))
    |> Map.put(:max, event.max |> Decimal.to_string(:normal))
    |> Map.put(:qty, event.qty |> Decimal.to_string(:normal))
  end
end
