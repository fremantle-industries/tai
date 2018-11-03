defmodule Tai.Events.LockAssetBalanceRangeOk do
  @type t :: %Tai.Events.LockAssetBalanceRangeOk{
          asset: atom,
          qty: Decimal.t(),
          min: Decimal.t(),
          max: Decimal.t()
        }

  @enforce_keys [:asset, :qty, :min, :max]
  defstruct [:asset, :qty, :min, :max]
end
