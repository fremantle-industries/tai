defmodule Tai.Commands.Balance do
  @moduledoc """
  Display symbols on each exchange with a non-zero balance
  """

  alias TableRex.Table

  @spec balance :: no_return
  def balance do
    fetch_balances()
    |> format_rows()
    |> exclude_empty_balances()
    |> render!()
  end

  defp fetch_balances do
    Tai.Exchanges.AssetBalances.all()
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
          Tai.Exchanges.AssetBalance.total(balance)
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

  @header [
    "Exchange",
    "Account",
    "Asset",
    "Free",
    "Locked",
    "Balance"
  ]
  @spec render!(list) :: no_return
  defp render!(rows)

  defp render!([]) do
    col_count = @header |> Enum.count()

    [List.duplicate("-", col_count)]
    |> render!
  end

  defp render!(rows) do
    rows
    |> Table.new(@header)
    |> Table.put_column_meta(:all, align: :right)
    |> Table.render!()
    |> IO.puts()
  end
end
