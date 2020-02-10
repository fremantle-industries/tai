defmodule Tai.Venues.Start.Accounts do
  @type venue :: Tai.Venue.t()
  @type credential_id :: Tai.Venue.credential_id()
  @type credential_error :: {credential_id, Tai.Venues.Client.shared_error_reason()}

  @spec hydrate(venue) :: :ok | {:error, reason :: [credential_error]}
  def hydrate(venue) do
    venue
    |> fetch
    |> filter
    |> store
    |> broadcast_result
  end

  defp fetch(venue) do
    venue.credentials
    |> Map.keys()
    |> Enum.map(fn credential_id ->
      try do
        response = Tai.Venues.Client.accounts(venue, credential_id)
        {response, credential_id}
      rescue
        e ->
          {{:error, {e, __STACKTRACE__}}, credential_id}
      end
    end)
    |> Enum.reduce(
      {:ok, []},
      fn
        {{:ok, credential_accounts}, _}, {:ok, accounts} ->
          {:ok, accounts ++ credential_accounts}

        {{:error, reason}, credential_id}, {:ok, _} ->
          {:error, [{credential_id, reason}]}

        {{:error, reason}, credential_id}, {:error, reasons} ->
          {:error, reasons ++ [{credential_id, reason}]}
      end
    )
    |> case do
      {:ok, accounts} -> {:ok, venue, accounts}
      {:error, _reasons} = error -> error
    end
  end

  defp filter({:ok, venue, accounts}) do
    total = accounts |> Enum.count()
    filtered_accounts = accounts |> apply_filter(venue.accounts)
    {:ok, venue, total, filtered_accounts}
  end

  defp filter({:error, _reasons} = error) do
    error
  end

  defp store({:ok, _, _, accounts} = result) do
    accounts |> Enum.each(&Tai.Venues.AccountStore.put/1)
    result
  end

  defp store({:error, _reasons} = error) do
    error
  end

  defp broadcast_result({:ok, venue, total, filtered_accounts}) do
    %Tai.Events.HydrateAccounts{
      venue_id: venue.id,
      total: total,
      filtered: filtered_accounts |> Enum.count()
    }
    |> TaiEvents.info()

    {:ok, filtered_accounts}
  end

  defp broadcast_result({:error, _reasons} = error) do
    error
  end

  defp apply_filter(accounts, {mod, func_name}) do
    apply(mod, func_name, [accounts])
  end

  defp apply_filter(accounts, query) when is_binary(query) do
    accounts
    |> Enum.group_by(& &1.asset)
    |> Juice.squeeze(query)
    |> Map.values()
    |> Enum.flat_map(& &1)
  end
end
