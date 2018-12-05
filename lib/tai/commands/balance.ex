defmodule Tai.Commands.Balance do
  @moduledoc """
  Display symbols on each exchange with a non-zero balance
  """

  import Tai.Commands.Table, only: [render!: 2]

  @header [
    "Exchange",
    "Account",
    "Asset",
    "Free",
    "Locked",
    "Balance"
  ]

  @spec balance :: no_return
  def balance do
    fetch_balances()
    |> format_rows()
    |> exclude_empty_balances()
    |> render!(@header)
  end

  defp fetch_balances do
    Tai.Venues.AssetBalances.all()
    |> Enum.sort(&(&1.asset >= &2.asset))
    |> Enum.sort(&(&1.exchange_id >= &2.exchange_id))
    |> Enum.reduce(
      [],
      fn balance, acc ->
        row = {
          balance.exchange_id,
          balance.account_id,
          balance.asset,
          balance.free,
          balance.locked,
          Tai.Venues.AssetBalance.total(balance)
        }

        [row | acc]
      end
    )
  end

  defp exclude_empty_balances(balances) do
    Enum.reject(
      balances,
      fn [_, _, _, _, _, total] -> Tai.Markets.Asset.zero?(total) end
    )
  end

  defp format_rows(balances) do
    balances
    |> Enum.map(fn {exchange_id, account_id, symbol, free, locked, total} ->
      formatted_free = Tai.Markets.Asset.new(free, symbol)
      formatted_locked = Tai.Markets.Asset.new(locked, symbol)
      formatted_total = Tai.Markets.Asset.new(total, symbol)
      [exchange_id, account_id, symbol, formatted_free, formatted_locked, formatted_total]
    end)
  end
end
