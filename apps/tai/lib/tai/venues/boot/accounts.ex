defmodule Tai.Venues.Boot.Accounts do
  @type venue :: Tai.Venue.t()
  @type credential_id :: Tai.Venue.credential_id()
  @type credential_error :: {credential_id, Tai.Venues.Client.shared_error_reason()}

  @spec hydrate(venue) :: :ok | {:error, reason :: [credential_error]}
  def hydrate(venue) do
    venue.credentials
    |> Map.keys()
    |> Enum.map(&fetch(&1, venue))
    |> Enum.reduce(:ok, &upsert/2)
  end

  defp fetch(credential_id, venue) do
    result = Tai.Venues.Client.accounts(venue, credential_id)
    {credential_id, result}
  end

  defp upsert({_credential_id, {:ok, accounts}}, acc) do
    accounts |> Enum.each(&Tai.Venues.AccountStore.upsert/1)
    acc
  end

  defp upsert({_credential_id, {:error, _reason}} = response, :ok) do
    upsert(response, {:error, []})
  end

  defp upsert({credential_id, {:error, reason}}, {:error, reasons}) do
    {:error, reasons ++ [{credential_id, reason}]}
  end
end
