defmodule Tai.Events.LockAssetBalanceRangeInsufficientFunds do
  @type t :: %Tai.Events.LockAssetBalanceRangeInsufficientFunds{
          asset: atom,
          free: Decimal.t(),
          min: Decimal.t(),
          max: Decimal.t()
        }

  @enforce_keys [:asset, :free, :min, :max]
  defstruct [:asset, :free, :min, :max]
end
