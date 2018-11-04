defmodule Tai.Events.LockAssetBalanceRangeInsufficientFunds do
  @type t :: %Tai.Events.LockAssetBalanceRangeInsufficientFunds{
          venue_id: atom,
          account_id: atom,
          asset: atom,
          free: Decimal.t(),
          min: Decimal.t(),
          max: Decimal.t()
        }

  @enforce_keys [
    :venue_id,
    :account_id,
    :asset,
    :free,
    :min,
    :max
  ]
  defstruct [
    :venue_id,
    :account_id,
    :asset,
    :free,
    :min,
    :max
  ]
end
