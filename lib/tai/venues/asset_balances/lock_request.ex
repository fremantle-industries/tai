defmodule Tai.Venues.AssetBalances.LockRequest do
  alias Tai.Venues.AssetBalances

  @type t :: %AssetBalances.LockRequest{
          venue_id: atom,
          account_id: atom,
          asset: atom,
          min: Decimal.t(),
          max: Decimal.t()
        }

  @enforce_keys ~w(venue_id account_id asset min max)a
  defstruct ~w(venue_id account_id asset min max)a
end
