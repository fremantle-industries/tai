defmodule Tai.VenueAdapters.OkEx.AssetBalances do
  def asset_balances(venue_id, account_id, credentials) do
    with {:ok, %{"info" => info}} <-
           credentials
           |> to_venue_credentials
           |> ExOkex.Futures.list_accounts() do
      balances =
        info
        |> Enum.map(fn {asset, %{"equity" => equity}} ->
          free = Decimal.new(0)
          locked = Decimal.new(equity)

          %Tai.Venues.AssetBalance{
            exchange_id: venue_id,
            account_id: account_id,
            asset: asset |> String.to_atom(),
            free: free,
            locked: locked
          }
        end)

      {:ok, balances}
    end
  end

  defp to_venue_credentials(credentials), do: struct(ExOkex.Config, credentials)
end
