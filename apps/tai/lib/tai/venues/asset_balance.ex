defmodule Tai.Venues.AssetBalance do
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type account_id :: Tai.Venues.Adapter.account_id()
  @type asset :: atom
  @type t :: %Tai.Venues.AssetBalance{
          venue_id: venue_id,
          account_id: account_id,
          asset: asset,
          free: Decimal.t(),
          locked: Decimal.t()
        }

  @enforce_keys ~w(
    venue_id
    account_id
    asset
    free
    locked
  )a
  defstruct ~w(
    venue_id
    account_id
    asset
    free
    locked
  )a

  @spec total(balance :: t) :: Decimal.t()
  def total(%Tai.Venues.AssetBalance{free: free, locked: locked}) do
    Decimal.add(free, locked)
  end
end
