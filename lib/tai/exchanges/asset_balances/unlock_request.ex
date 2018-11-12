defmodule Tai.Exchanges.AssetBalances.UnlockRequest do
  alias Tai.Exchanges.AssetBalances

  @type t :: %AssetBalances.UnlockRequest{
          exchange_id: atom,
          account_id: atom,
          asset: atom,
          qty: Decimal.t()
        }

  @enforce_keys [:exchange_id, :account_id, :asset, :qty]
  defstruct [:exchange_id, :account_id, :asset, :qty]
end
