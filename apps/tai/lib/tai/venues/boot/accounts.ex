defmodule Tai.Venues.Boot.Accounts do
  @type venue :: Tai.Venue.t()
  @type credential_id :: Tai.Venue.credential_id()
  @type credential_error :: {credential_id, Tai.Venues.Client.shared_error_reason()}

  @spec hydrate(venue) :: :ok | {:error, reason :: [credential_error]}
  def hydrate(venue) do
    venue.credentials
    |> Map.keys()
    |> Enum.map(&fetch(&1, venue))
    |> Enum.reduce(:ok, &put/2)
  end

  defp fetch(credential_id, venue) do
    result = Tai.Venues.Client.accounts(venue, credential_id)
    {credential_id, venue, result}
  end

  defp put({_credential_id, venue, {:ok, accounts}}, acc) do
    accounts
    |> filter(venue.accounts)
    |> Enum.each(&Tai.Venues.AccountStore.put/1)

    acc
  end

  defp put({_credential_id, _venue, {:error, _reason}} = response, :ok) do
    put(response, {:error, []})
  end

  defp put({credential_id, _venue, {:error, reason}}, {:error, reasons}) do
    {:error, reasons ++ [{credential_id, reason}]}
  end

  defp filter(accounts, filter) when is_function(filter) do
    accounts |> filter.()
  end

  defp filter(accounts, filter) do
    accounts
    |> Enum.group_by(& &1.asset)
    |> Juice.squeeze(filter)
    |> Map.values()
    |> Enum.flat_map(& &1)
  end
end
