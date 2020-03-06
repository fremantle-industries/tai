defmodule Tai.Venues.Start.Positions do
  @type venue :: Tai.Venue.t()
  @type total :: pos_integer
  @type error_reason :: term

  @spec hydrate(venue) :: {:ok, total} | {:error, error_reason}
  def hydrate(venue) do
    venue
    |> fetch
    |> store
    |> broadcast_result
  end

  defp fetch(venue) do
    venue.credentials
    |> Map.keys()
    |> Enum.map(fn credential_id ->
      try do
        response = Tai.Venues.Client.positions(venue, credential_id)
        {response, credential_id}
      rescue
        e ->
          {{:error, {e, __STACKTRACE__}}, credential_id}
      end
    end)
    |> Enum.reduce(
      {:ok, []},
      fn
        {{:ok, credential_positions}, _}, {:ok, positions} ->
          {:ok, positions ++ credential_positions}

        {{:error, reason}, credential_id}, {:ok, _} ->
          {:error, [{credential_id, reason}]}

        {{:error, reason}, credential_id}, {:error, reasons} ->
          {:error, reasons ++ [{credential_id, reason}]}
      end
    )
    |> case do
      {:ok, positions} -> {:ok, venue, positions}
      {:error, reasons} -> {:error, venue, reasons}
    end
  end

  defp store({:ok, _, positions} = result) do
    Enum.each(positions, &Tai.Trading.PositionStore.put/1)
    result
  end

  defp store({:error, _venue, _reasons} = error) do
    error
  end

  defp broadcast_result({:ok, venue, positions}) do
    %Tai.Events.HydratePositions{
      venue_id: venue.id,
      total: Enum.count(positions)
    }
    |> TaiEvents.info()

    {:ok, positions}
  end

  defp broadcast_result({:error, venue, reasons}) do
    if Enum.all?(reasons, &not_supported_error?/1) do
      %Tai.Events.HydratePositions{
        venue_id: venue.id,
        total: 0
      }
      |> TaiEvents.info()

      {:ok, []}
    else
      {:error, reasons}
    end
  end

  defp not_supported_error?({_credential_id, :not_supported}), do: true
  defp not_supported_error?(_), do: false
end
