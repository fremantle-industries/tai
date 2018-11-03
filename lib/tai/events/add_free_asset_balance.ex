defmodule Tai.Events.AddFreeAssetBalance do
  @type t :: %Tai.Events.AddFreeAssetBalance{
          asset: atom,
          val: Decimal.t(),
          free: Decimal.t(),
          locked: Decimal.t()
        }

  @enforce_keys [:asset, :val, :free, :locked]
  defstruct [:asset, :val, :free, :locked]
end
