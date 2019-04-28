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

    key = Tai.VenueAdapters.Mock.asset_balances_response_key({venue_id, account_id})
    :ok = Tai.TestSupport.Mocks.Server.insert(key, balances)

    :ok
  end
end
