defmodule Tai.TestSupport.Mocks.Responses.AssetBalances do
  def for_exchange_and_account(venue_id, account_id, balances_attrs) do
    balances =
      balances_attrs
      |> Enum.map(fn attrs ->
        struct(
          Tai.Venues.AssetBalance,
          Map.merge(%{venue_id: venue_id, account_id: account_id}, attrs)
        )
      end)

    {:asset_balances, venue_id, account_id}
    |> Tai.TestSupport.Mocks.Server.insert(balances)
  end
end
