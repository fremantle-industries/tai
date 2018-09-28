defmodule Tai.Commands.Balance do
  @moduledoc """
  Display symbols on each exchange with a non-zero balance
  """

  alias TableRex.Table

  @spec balance :: no_return
  def balance do
    Tai.Exchanges.Config.all()
    |> group_by_exchange_accounts
    |> fetch_balances
    |> format_rows
    |> exclude_empty_balances
    |> render!
  end

  defp group_by_exchange_accounts(configs) do
    configs
    |> Enum.reduce(
      [],
      fn config, acc ->
        config.accounts
        |> Enum.reduce(
          acc,
          fn {account_id, _}, acc ->
            [{config.id, account_id} | acc]
          end
        )
      end
    )
    |> Enum.sort(fn {exchange_id_a, _}, {exchange_id_b, _} ->
      exchange_id_a |> Atom.to_string() >= exchange_id_b |> Atom.to_string()
    end)
  end

  defp fetch_balances(exchange_accounts) do
    exchange_accounts
    |> Enum.reduce(
      [],
      fn {exchange_id, account_id}, acc ->
        exchange_id
        |> Tai.Exchanges.AssetBalances.all(account_id)
        |> Enum.reverse()
        |> Enum.reduce(
          acc,
          fn {symbol, detail}, acc ->
            total = Tai.Exchanges.AssetBalance.total(detail)
            [{exchange_id, account_id, symbol, detail.free, detail.locked, total} | acc]
          end
        )
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

  @header ["Exchange", "Account", "Symbol", "Free", "Locked", "Balance"]
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
