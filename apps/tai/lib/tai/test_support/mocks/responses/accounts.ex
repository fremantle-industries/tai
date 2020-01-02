defmodule Tai.TestSupport.Mocks.Responses.Accounts do
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type credential_id :: Tai.Venues.Adapter.credential_id()
  @type account_attrs :: map

  @spec for_venue_and_credential(venue_id, credential_id, map) :: :ok
  def for_venue_and_credential(venue_id, credential_id, account_attrs) do
    base_attrs = %{venue_id: venue_id, credential_id: credential_id}

    accounts =
      account_attrs
      |> Enum.map(fn attrs ->
        attrs = Map.merge(base_attrs, attrs)
        struct(Tai.Venues.Account, attrs)
      end)

    {:accounts, venue_id, credential_id}
    |> Tai.TestSupport.Mocks.Server.insert(accounts)
  end
end
