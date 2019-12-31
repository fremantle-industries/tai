defmodule Tai.Venues.Boot.Positions do
  @type venue :: Tai.Venue.t()

  @spec hydrate(venue) :: {:ok, total :: pos_integer} | {:error, reason :: term}
  def hydrate(venue) do
    venue.credentials
    |> Enum.reduce(
      :ok,
      &fetch_and_add(&1, &2, venue)
    )
  end

  defp fetch_and_add({credential_id, _}, :ok, venue) do
    with {:ok, positions} <- Tai.Venues.Client.positions(venue, credential_id) do
      Enum.each(positions, &Tai.Trading.PositionStore.add/1)
      total = Enum.count(positions)

      Tai.Events.info(%Tai.Events.HydratePositions{
        venue_id: venue.id,
        total: total
      })

      {:ok, total}
    else
      {:error, :not_supported} -> {:ok, 0}
      {:error, _} = error -> error
    end
  end

  defp fetch_and_add({_, _}, {:error, _} = error, _), do: error
end
