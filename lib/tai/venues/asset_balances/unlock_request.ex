defmodule Tai.Venues.AssetBalances.UnlockRequest do
  alias Tai.Venues.AssetBalances

  @type t :: %AssetBalances.UnlockRequest{
          venue_id: atom,
          account_id: atom,
          asset: atom,
          qty: Decimal.t()
        }

  @enforce_keys ~w(venue_id account_id asset qty)a
  defstruct ~w(venue_id account_id asset qty)a
end
