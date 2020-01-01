defmodule Tai.Venues.Boot.Positions do
  @type adapter :: Tai.Venues.Adapter.t()

  @spec hydrate(adapter) :: {:ok, total :: pos_integer} | {:error, reason :: term}
  def hydrate(adapter) do
    adapter.accounts
    |> Enum.reduce(
      :ok,
      &fetch_and_add(&1, &2, adapter)
    )
  end

  defp fetch_and_add({account_id, _}, :ok, adapter) do
    with {:ok, positions} <- Tai.Venues.Client.positions(adapter, account_id) do
      Enum.each(positions, &Tai.Trading.PositionStore.add/1)
      total = Enum.count(positions)

      Tai.Events.info(%Tai.Events.HydratePositions{
        venue_id: adapter.id,
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
