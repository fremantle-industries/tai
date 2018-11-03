defmodule Tai.Events.UnlockAssetBalanceInsufficientFunds do
  @type t :: %Tai.Events.UnlockAssetBalanceInsufficientFunds{
          asset: atom,
          qty: Decimal.t(),
          locked: Decimal.t()
        }

  @enforce_keys [:asset, :qty, :locked]
  defstruct [:asset, :qty, :locked]
end
