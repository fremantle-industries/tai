defmodule Tai.VenueAdapters.DeltaExchange.Accounts do
  def accounts(_venue_id, _credential_id, _credentials) do
    # venue_credentials = struct!(ExDeltaExchange.Credentials, credentials)

    # with {:ok, balances} <- ExDeltaExchange.Wallet.Balances.get(venue_credentials) do
    #   accounts = balances |> Enum.map(&build(&1, venue_id, credential_id))
    #   {:ok, accounts}
    # end

    {:ok, []}
  end
end
