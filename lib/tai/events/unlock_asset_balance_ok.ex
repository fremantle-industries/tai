defmodule Tai.Events.UnlockAssetBalanceOk do
  @type t :: %Tai.Events.UnlockAssetBalanceOk{
          asset: atom,
          qty: Decimal.t()
        }

  @enforce_keys [:asset, :qty]
  defstruct [:asset, :qty]
end
