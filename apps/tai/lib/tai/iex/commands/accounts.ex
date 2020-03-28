defmodule Tai.IEx.Commands.Accounts do
  @moduledoc """
  Display accounts on each exchange with a non-zero balance
  """

  import Tai.IEx.Commands.Table, only: [render!: 2]

  @header [
    "Venue",
    "Credential",
    "Asset",
    "Free",
    "Locked",
    "Equity"
  ]

  @spec accounts :: no_return
  def accounts do
    fetch_accounts()
    |> format_rows()
    |> render!(@header)
  end

  defp fetch_accounts do
    Tai.Commander.accounts()
    |> Enum.reduce(
      [],
      fn account, acc ->
        row = {
          account.venue_id,
          account.credential_id,
          account.asset,
          account.free,
          account.locked,
          account.equity
        }

        [row | acc]
      end
    )
  end

  defp format_rows(accounts) do
    accounts
    |> Enum.map(fn {venue_id, credential_id, symbol, free, locked, total} ->
      formatted_free = Tai.Markets.Asset.new(free, symbol)
      formatted_locked = Tai.Markets.Asset.new(locked, symbol)
      formatted_total = Tai.Markets.Asset.new(total, symbol)
      [venue_id, credential_id, symbol, formatted_free, formatted_locked, formatted_total]
    end)
  end
end
