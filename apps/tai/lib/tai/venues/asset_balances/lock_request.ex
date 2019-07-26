defmodule Tai.Venues.AssetBalances.LockRequest do
  alias Tai.Venues.AssetBalances

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type account_id :: Tai.Venues.Adapter.account_id()
  @type asset :: Tai.Venues.AssetBalance.asset()
  @type t :: %AssetBalances.LockRequest{
          venue_id: venue_id,
          account_id: account_id,
          asset: asset,
          min: Decimal.t(),
          max: Decimal.t()
        }

  @enforce_keys ~w(venue_id account_id asset min max)a
  defstruct ~w(venue_id account_id asset min max)a
end
