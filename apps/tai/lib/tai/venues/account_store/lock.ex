defmodule Tai.Venues.AccountStore.Lock do
  alias Tai.Venues.AccountStore

  @type lock_request :: AccountStore.LockRequest.t()

  @spec from_request(lock_request) ::
          {:ok, {term, Decimal.t()}}
          | {:error, :min_less_than_zero | :min_greater_than_max | :not_found}
          | {:error, {:insufficient_balance, free :: Decimal.t()}}
  def from_request(%AccountStore.LockRequest{
        venue_id: venue_id,
        credential_id: credential_id,
        asset: asset,
        min: min,
        max: max
      }) do
    with :ok <- validate(min, max),
         {:ok, balance} <-
           AccountStore.find_by(
             venue_id: venue_id,
             credential_id: credential_id,
             asset: asset
           ) do
      lock_qty =
        cond do
          Decimal.cmp(max, balance.free) != :gt -> max
          Decimal.cmp(min, balance.free) != :gt -> balance.free
          true -> nil
        end

      if lock_qty == nil do
        {:error, {:insufficient_balance, balance.free}}
      else
        new_free = Decimal.sub(balance.free, lock_qty)
        new_locked = Decimal.add(balance.locked, lock_qty)

        with_locked_balance =
          balance
          |> Map.put(:free, new_free)
          |> Map.put(:locked, new_locked)

        {:ok, {with_locked_balance, lock_qty}}
      end
    end
  end

  defp validate(min, max) do
    cond do
      Decimal.cmp(min, Decimal.new(0)) == :lt ->
        {:error, :min_less_than_zero}

      Decimal.cmp(min, max) == :gt ->
        {:error, :min_greater_than_max}

      true ->
        :ok
    end
  end
end
