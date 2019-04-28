defmodule Tai.VenueAdapters.Gdax.AssetBalances do
  def asset_balances(venue_id, account_id, credentials) do
    with {:ok, raw_accounts} <- ExGdax.list_accounts(credentials) do
      accounts =
        Enum.map(
          raw_accounts,
          &build(&1, venue_id, account_id)
        )

      {:ok, accounts}
    else
      {:error, "Invalid Passphrase" = reason, _status} ->
        {:error, {:credentials, reason}}

      {:error, "Invalid API Key" = reason, _status} ->
        {:error, {:credentials, reason}}

      {:error, reason, 503} ->
        {:error, %Tai.ServiceUnavailableError{reason: reason}}

      {:error, "timeout"} ->
        {:error, :timeout}
    end
  end

  def build(
        %{"currency" => raw_currency, "available" => available, "hold" => hold},
        venue_id,
        account_id
      ) do
    asset =
      raw_currency
      |> String.downcase()
      |> String.to_atom()

    %Tai.Venues.AssetBalance{
      venue_id: venue_id,
      account_id: account_id,
      asset: asset,
      free: available |> Decimal.new() |> Decimal.reduce(),
      locked: hold |> Decimal.new() |> Decimal.reduce()
    }
  end
end
