defmodule Tai.Venues.AssetBalances.UnlockRequest do
  alias Tai.Venues.AssetBalances

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type account_id :: Tai.Venues.Adapter.account_id()
  @type asset :: Tai.Venues.AssetBalance.asset()
  @type t :: %AssetBalances.UnlockRequest{
          venue_id: venue_id,
          account_id: account_id,
          asset: asset,
          qty: Decimal.t()
        }

  @enforce_keys ~w(venue_id account_id asset qty)a
  defstruct ~w(venue_id account_id asset qty)a
end
