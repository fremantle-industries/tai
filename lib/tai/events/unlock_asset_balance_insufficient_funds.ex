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
