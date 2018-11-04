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
