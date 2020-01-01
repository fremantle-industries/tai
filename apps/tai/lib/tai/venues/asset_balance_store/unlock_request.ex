defmodule Tai.Venues.AssetBalanceStore.UnlockRequest do
  alias Tai.Venues.AssetBalanceStore

  @type venue_id :: Tai.Venue.id()
  @type account_id :: Tai.Venue.account_id()
  @type asset :: Tai.Venues.AssetBalance.asset()
  @type t :: %AssetBalanceStore.UnlockRequest{
          venue_id: venue_id,
          account_id: account_id,
          asset: asset,
          qty: Decimal.t()
        }

  @enforce_keys ~w(venue_id account_id asset qty)a
  defstruct ~w(venue_id account_id asset qty)a
end
