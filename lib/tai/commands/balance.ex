defmodule Tai.Commands.Balance do
  @moduledoc """
  Display symbols on each exchange with a non-zero balance
  """

  alias Tai.{Exchanges, Markets.Asset}
  alias TableRex.Table

  @spec balance :: no_return
  def balance do
    Exchanges.Config.account_ids()
    |> fetch_balances
    |> format_rows
    |> exclude_empty_balances
    |> render!
  end

  defp fetch_balances(account_ids) do
    account_ids
    |> Enum.sort()
    |> Enum.reverse()
    |> Enum.reduce(
      [],
      fn account_id, acc ->
        account_id
        |> Exchanges.Balance.all()
        |> Enum.reverse()
        |> Enum.reduce(
          acc,
          fn {symbol, detail}, acc ->
            total = Tai.Exchanges.BalanceDetail.total(detail)
            [{account_id, symbol, detail.free, detail.locked, total} | acc]
          end
        )
      end
    )
  end

  defp exclude_empty_balances(balances) do
    balances
    |> Enum.reject(fn [_, _, _, _, total] -> Asset.zero?(total) end)
  end

  defp format_rows(balances) do
    balances
    |> Enum.map(fn {exchange_id, symbol, free, locked, total} ->
      formatted_free = Asset.new(free, symbol)
      formatted_locked = Asset.new(locked, symbol)
      formatted_total = Asset.new(total, symbol)
      [exchange_id, symbol, formatted_free, formatted_locked, formatted_total]
    end)
  end

  @header ["Account", "Symbol", "Free", "Locked", "Balance"]
  @spec render!(list) :: no_return
  defp render!(rows) do
    rows
    |> Table.new(@header)
    |> Table.put_column_meta(:all, align: :right)
    |> Table.render!()
    |> IO.puts()
  end
end
