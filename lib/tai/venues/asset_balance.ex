defmodule Tai.Venues.AssetBalance do
  @type t :: %Tai.Venues.AssetBalance{
          exchange_id: atom,
          account_id: atom,
          asset: atom,
          free: Decimal.t(),
          locked: Decimal.t()
        }

  @enforce_keys [
    :exchange_id,
    :account_id,
    :asset,
    :free,
    :locked
  ]
  defstruct [
    :exchange_id,
    :account_id,
    :asset,
    :free,
    :locked
  ]

  @spec total(balance :: t) :: Decimal.t()
  def total(%Tai.Venues.AssetBalance{free: free, locked: locked}) do
    Decimal.add(free, locked)
  end
end
