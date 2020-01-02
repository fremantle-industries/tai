defmodule Tai.VenueAdapters.OkEx.Accounts do
  def accounts(venue_id, credential_id, credentials) do
    with venue_credentials <- credentials |> to_venue_credentials,
         {:ok, futures} <- fetch_futures(venue_id, credential_id, venue_credentials),
         {:ok, swap} <- fetch_swap(venue_id, credential_id, venue_credentials),
         {:ok, spot} <- fetch_spot(venue_id, credential_id, venue_credentials) do
      {:ok, futures ++ swap ++ spot}
    end
  end

  def fetch_futures(venue_id, credential_id, venue_credentials) do
    with {:ok, %{"info" => info}} <- ExOkex.Futures.Private.list_accounts(venue_credentials) do
      accounts =
        info
        |> Enum.map(fn {asset, %{"equity" => equity}} ->
          free = Decimal.new(0)
          locked = equity |> Decimal.new() |> Decimal.reduce()

          %Tai.Venues.Account{
            venue_id: venue_id,
            credential_id: credential_id,
            asset: asset |> String.to_atom(),
            type: "futures",
            free: free,
            locked: locked
          }
        end)

      {:ok, accounts}
    end
  end

  def fetch_swap(venue_id, credential_id, venue_credentials) do
    with {:ok, %{"info" => swap_accounts}} <- ExOkex.Swap.Private.list_accounts(venue_credentials) do
      accounts =
        swap_accounts
        |> Enum.map(fn %{"instrument_id" => instrument_id, "equity" => equity} ->
          asset =
            instrument_id
            |> String.split("-")
            |> Enum.at(0)
            |> String.downcase()
            |> String.to_atom()

          free = Decimal.new(0)
          locked = equity |> Decimal.new() |> Decimal.reduce()

          %Tai.Venues.Account{
            venue_id: venue_id,
            credential_id: credential_id,
            asset: asset,
            type: "swap",
            free: free,
            locked: locked
          }
        end)

      {:ok, accounts}
    end
  end

  def fetch_spot(venue_id, credential_id, venue_credentials) do
    with {:ok, spot_accounts} <- ExOkex.Spot.Private.list_accounts(venue_credentials) do
      accounts =
        spot_accounts
        |> Enum.map(fn %{
                         "currency" => currency,
                         "balance" => venue_balance,
                         "available" => available
                       } ->
          asset = currency |> String.downcase() |> String.to_atom()
          free = available |> Decimal.new()
          locked = venue_balance |> Decimal.new() |> Decimal.sub(free) |> Decimal.reduce()

          %Tai.Venues.Account{
            venue_id: venue_id,
            credential_id: credential_id,
            asset: asset,
            type: "spot",
            free: free,
            locked: locked
          }
        end)

      {:ok, accounts}
    end
  end

  defp to_venue_credentials(credentials), do: struct!(ExOkex.Config, credentials)
end
