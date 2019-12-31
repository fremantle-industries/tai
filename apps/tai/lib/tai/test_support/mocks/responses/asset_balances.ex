defmodule Tai.TestSupport.Mocks.Responses.AssetBalances do
  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()

  @deprecated "Use Tai.TestSupport.Mocks.Responses.AssetBalances.for_venue_and_credential/3 instead."
  @spec for_venue_and_account(venue_id, credential_id, map) :: :ok
  def for_venue_and_account(venue_id, credential_id, balances_attrs) do
    for_venue_and_credential(venue_id, credential_id, balances_attrs)
  end

  @spec for_venue_and_credential(venue_id, credential_id, map) :: :ok
  def for_venue_and_credential(venue_id, credential_id, balances_attrs) do
    balances =
      balances_attrs
      |> Enum.map(fn attrs ->
        struct(
          Tai.Venues.AssetBalance,
          Map.merge(%{venue_id: venue_id, account_id: credential_id}, attrs)
        )
      end)

    {:asset_balances, venue_id, credential_id}
    |> Tai.TestSupport.Mocks.Server.insert(balances)
  end
end
