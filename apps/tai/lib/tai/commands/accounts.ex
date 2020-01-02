defmodule Tai.Commands.Accounts do
  @moduledoc """
  Display accounts on each exchange with a non-zero balance
  """

  import Tai.Commands.Table, only: [render!: 2]

  @header [
    "Venue",
    "Credential",
    "Asset",
    "Free",
    "Locked",
    "Balance"
  ]

  @spec accounts :: no_return
  def accounts do
    fetch_accounts()
    |> format_rows()
    |> exclude_zero_balances()
    |> render!(@header)
  end

  defp fetch_accounts do
    Tai.Venues.AccountStore.all()
    |> Enum.sort(&(&1.asset >= &2.asset))
    |> Enum.sort(&(&1.venue_id >= &2.venue_id))
    |> Enum.reduce(
      [],
      fn account, acc ->
        row = {
          account.venue_id,
          account.credential_id,
          account.asset,
          account.free,
          account.locked,
          Tai.Venues.Account.total(account)
        }

        [row | acc]
      end
    )
  end

  defp exclude_zero_balances(accounts) do
    Enum.reject(
      accounts,
      fn [_, _, _, _, _, total] -> Tai.Markets.Asset.zero?(total) end
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
