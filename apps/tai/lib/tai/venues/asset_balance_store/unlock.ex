defmodule Tai.Venues.AssetBalanceStore.Unlock do
  alias Tai.Venues.AssetBalanceStore

  @type unlock_request :: AssetBalanceStore.UnlockRequest.t()

  @spec from_request(unlock_request) ::
          {:ok, term}
          | {:error, :insufficient_balance}
          | {:error, :not_found}
  def from_request(%AssetBalanceStore.UnlockRequest{
        venue_id: venue_id,
        credential_id: credential_id,
        asset: asset,
        qty: qty
      }) do
    with {:ok, balance} <-
           AssetBalanceStore.find_by(
             venue_id: venue_id,
             credential_id: credential_id,
             asset: asset
           ) do
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
