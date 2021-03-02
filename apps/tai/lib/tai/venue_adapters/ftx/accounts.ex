defmodule Tai.VenueAdapters.Ftx.Accounts do
  def accounts(venue_id, credential_id, credentials) do
    venue_credentials = struct!(ExFtx.Credentials, credentials)

    with {:ok, balances} <- ExFtx.Wallet.Balances.get(venue_credentials) do
      accounts = balances |> Enum.map(&build(&1, venue_id, credential_id))
      {:ok, accounts}
    end
  end

  defp build(balance, venue_id, credential_id) do
    asset =
      balance.coin
      |> String.downcase()
      |> String.to_atom()

    free = balance.free |> Tai.Utils.Decimal.cast!() |> Decimal.normalize()
    # TODO: What does locked mean when there is portfolio margin???
    # locked = venue_locked |> Decimal.new() |> Decimal.normalize()
    locked = Decimal.new(0)
    # TODO: What does equity mean when there is portfolio margin??? Is total the correct choice
    # equity = Decimal.add(free, locked)
    equity = balance.total |> Tai.Utils.Decimal.cast!() |> Decimal.normalize()

    %Tai.Venues.Account{
      venue_id: venue_id,
      credential_id: credential_id,
      asset: asset,
      type: "default",
      equity: equity,
      free: free,
      locked: locked
    }
  end
end
