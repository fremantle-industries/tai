defmodule Tai.Events.UnlockAssetBalanceInsufficientFunds do
  @type t :: %Tai.Events.UnlockAssetBalanceInsufficientFunds{
          venue_id: atom,
          account_id: atom,
          asset: atom,
          qty: Decimal.t(),
          locked: Decimal.t()
        }

  @enforce_keys [
    :venue_id,
    :account_id,
    :asset,
    :qty,
    :locked
  ]
  defstruct [
    :venue_id,
    :account_id,
    :asset,
    :qty,
    :locked
  ]
end

defimpl Tai.LogEvent, for: Tai.Events.UnlockAssetBalanceInsufficientFunds do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:qty, event.qty |> Decimal.to_string(:normal))
    |> Map.put(:locked, event.locked |> Decimal.to_string(:normal))
  end
end
