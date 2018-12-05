defmodule Tai.Venues.AssetBalances.LockRequest do
  alias Tai.Venues.AssetBalances

  @type t :: %AssetBalances.LockRequest{
          exchange_id: atom,
          account_id: atom,
          asset: atom,
          min: Decimal.t(),
          max: Decimal.t()
        }

  @enforce_keys [:exchange_id, :account_id, :asset, :min, :max]
  defstruct [:exchange_id, :account_id, :asset, :min, :max]
end
