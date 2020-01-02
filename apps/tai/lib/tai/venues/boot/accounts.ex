defmodule Tai.Venues.Boot.Accounts do
  @type venue :: Tai.Venue.t()

  @spec hydrate(venue) :: :ok | {:error, reason :: term}
  def hydrate(venue) do
    venue.credentials
    |> Enum.reduce(
      :ok,
      &fetch_and_upsert(&1, &2, venue)
    )
  end

  defp fetch_and_upsert({credential_id, _}, :ok, venue) do
    with {:ok, accounts} <- Tai.Venues.Client.accounts(venue, credential_id) do
      Enum.each(accounts, &Tai.Venues.AccountStore.upsert/1)
      :ok
    else
      {:error, _} = error ->
        error
    end
  end

  defp fetch_and_upsert({_, _}, {:error, _} = error, _), do: error
end
