defmodule Tai.Events.LockAssetBalanceRangeOk do
  @type t :: %Tai.Events.LockAssetBalanceRangeOk{
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
