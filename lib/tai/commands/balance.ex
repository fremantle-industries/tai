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
          fn {symbol, balance}, acc ->
            [{account_id, symbol, balance} | acc]
          end
        )
      end
    )
  end

  defp exclude_empty_balances(balances) do
    balances
    |> Enum.reject(fn [_, _, ab] -> Asset.zero?(ab) end)
  end

  defp format_rows(balances) do
    balances
    |> Enum.map(fn {exchange_id, symbol, balance} ->
      asset_balance = Asset.new(balance, symbol)
      [exchange_id, symbol, asset_balance]
    end)
  end

  @header ["Account", "Symbol", "Balance"]
  @spec render!(list) :: no_return
  defp render!(rows) do
    rows
    |> Table.new(@header)
    |> Table.put_column_meta(:all, align: :right)
    |> Table.render!()
    |> IO.puts()
  end
end
