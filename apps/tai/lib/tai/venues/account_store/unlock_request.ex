defmodule Tai.Venues.AccountStore.UnlockRequest do
  alias Tai.Venues.AccountStore

  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type asset :: Tai.Venues.Account.asset()
  @type t :: %AccountStore.UnlockRequest{
          venue_id: venue_id,
          credential_id: credential_id,
          asset: asset,
          qty: Decimal.t()
        }

  @enforce_keys ~w(venue_id credential_id asset qty)a
  defstruct ~w(venue_id credential_id asset qty)a
end
