defmodule Tai.TestSupport.Mocks.Responses.AssetBalances do
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type account_id :: Tai.Venues.Adapter.account_id()

  @spec for_venue_and_account(venue_id, account_id, map) :: :ok
  def for_venue_and_account(venue_id, account_id, balances_attrs) do
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

  @deprecated "Use Tai.TestSupport.Mocks.Responses.AssetBalances.for_venue_and_account/3 instead."
  def for_exchange_and_account(venue_id, account_id, balances_attrs) do
    for_venue_and_account(venue_id, account_id, balances_attrs)
  end
end
