defmodule Tai.Venues.Boot.AssetBalances do
  @type adapter :: Tai.Venues.Adapter.t()

  @spec hydrate(adapter :: adapter) :: :ok | {:error, reason :: term}
  def hydrate(adapter) do
    adapter.accounts
    |> Enum.reduce(
      :ok,
      &fetch_and_upsert(&1, &2, adapter)
    )
  end

  defp fetch_and_upsert({account_id, _}, :ok, adapter) do
    with {:ok, balances} <- Tai.Exchanges.Exchange.asset_balances(adapter, account_id) do
      Enum.each(balances, &Tai.Venues.AssetBalances.upsert/1)
      :ok
    else
      {:error, _} = error ->
        error
    end
  end

  defp fetch_and_upsert({_, _}, {:error, _} = error, _), do: error
end
