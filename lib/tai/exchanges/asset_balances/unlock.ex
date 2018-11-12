defmodule Tai.Exchanges.AssetBalances.Unlock do
  alias Tai.Exchanges.AssetBalances

  @type unlock_request :: AssetBalances.UnlockRequest.t()

  @spec from_request(unlock_request) ::
          {:ok, term}
          | {:error, :insufficient_balance}
          | {:error, :not_found}
  def from_request(%AssetBalances.UnlockRequest{
        exchange_id: exchange_id,
        account_id: account_id,
        asset: asset,
        qty: qty
      }) do
    with {:ok, balance} <-
           AssetBalances.find_by(exchange_id: exchange_id, account_id: account_id, asset: asset) do
      new_free = Decimal.add(balance.free, qty)
      new_locked = Decimal.sub(balance.locked, qty)

      if Decimal.cmp(new_locked, Decimal.new(0)) == :lt do
        {:error, {:insufficient_balance, balance.locked}}
      else
        with_unlocked_balance =
          balance
          |> Map.put(:free, new_free)
          |> Map.put(:locked, new_locked)

        {:ok, with_unlocked_balance}
      end
    end
  end
end
