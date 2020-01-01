defmodule Tai.Venues.AssetBalanceStore.LockRequest do
  alias Tai.Venues.AssetBalanceStore

  @type venue_id :: Tai.Venue.id()
  @type account_id :: Tai.Venue.account_id()
  @type asset :: Tai.Venues.AssetBalance.asset()
  @type t :: %AssetBalanceStore.LockRequest{
          venue_id: venue_id,
          account_id: account_id,
          asset: asset,
          min: Decimal.t(),
          max: Decimal.t()
        }

  @enforce_keys ~w(venue_id account_id asset min max)a
  defstruct ~w(venue_id account_id asset min max)a
end
