defmodule Tai.Venues.AccountStore.LockRequest do
  alias Tai.Venues.AccountStore

  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type asset :: Tai.Venues.Account.asset()
  @type t :: %AccountStore.LockRequest{
          venue_id: venue_id,
          credential_id: credential_id,
          asset: asset,
          min: Decimal.t(),
          max: Decimal.t()
        }

  @enforce_keys ~w(venue_id credential_id asset min max)a
  defstruct ~w(venue_id credential_id asset min max)a
end
