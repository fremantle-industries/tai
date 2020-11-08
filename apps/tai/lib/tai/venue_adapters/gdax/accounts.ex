defmodule Tai.VenueAdapters.Gdax.Accounts do
  def accounts(venue_id, credential_id, credentials) do
    with {:ok, venue_accounts} <- ExGdax.list_accounts(credentials) do
      accounts =
        venue_accounts
        |> Enum.map(&build(&1, venue_id, credential_id))

      {:ok, accounts}
    else
      {:error, "Invalid Passphrase" = reason, _status} ->
        {:error, {:credentials, reason}}

      {:error, "Invalid API Key" = reason, _status} ->
        {:error, {:credentials, reason}}

      {:error, reason, 503} ->
        {:error, {:service_unavailable, reason}}

      {:error, "timeout"} ->
        {:error, :timeout}
    end
  end

  def build(
        %{"currency" => raw_currency, "available" => available, "hold" => hold},
        venue_id,
        credential_id
      ) do
    asset =
      raw_currency
      |> String.downcase()
      |> String.to_atom()

    free = available |> Decimal.new() |> Decimal.normalize()
    locked = hold |> Decimal.new() |> Decimal.normalize()
    equity = Decimal.add(free, locked)

    %Tai.Venues.Account{
      venue_id: venue_id,
      credential_id: credential_id,
      type: "default",
      asset: asset,
      equity: equity,
      free: free,
      locked: locked
    }
  end
end
