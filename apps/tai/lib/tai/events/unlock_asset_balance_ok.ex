defmodule Tai.Events.UnlockAssetBalanceOk do
  @type t :: %Tai.Events.UnlockAssetBalanceOk{
          venue_id: atom,
          account_id: atom,
          asset: atom,
          qty: Decimal.t()
        }

  @enforce_keys [
    :venue_id,
    :account_id,
    :asset,
    :qty
  ]
  defstruct [
    :venue_id,
    :account_id,
    :asset,
    :qty
  ]
end

defimpl Tai.LogEvent, for: Tai.Events.UnlockAssetBalanceOk do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:qty, event.qty |> Decimal.to_string(:normal))
  end
end
