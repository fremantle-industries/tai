defmodule Tai.VenueAdapters.Bitmex.Positions do
  def positions(venue_id, account_id, credentials) do
    venue_credentials = to_venue_credentials(credentials)

    with {:ok, venue_positions, _rate_limit} <- ExBitmex.Rest.Positions.all(venue_credentials) do
      positions = Enum.map(venue_positions, &build(&1, venue_id, account_id))

      {:ok, positions}
    else
      {:error, reason, _} ->
        {:error, reason}
    end
  end

  defdelegate to_venue_credentials(credentials),
    to: Tai.VenueAdapters.Bitmex.Credentials,
    as: :from

  defp build(position, venue_id, account_id) do
    # TODO: This should come from products
    product_symbol =
      position.symbol
      |> String.downcase()
      |> String.to_atom()

    %Tai.Trading.Position{
      venue_id: venue_id,
      account_id: account_id,
      product_symbol: product_symbol,
      open: position.is_open,
      avg_entry_price:
        position.avg_entry_price && position.avg_entry_price |> Tai.Utils.Decimal.from(),
      qty: position.current_qty |> Tai.Utils.Decimal.from(),
      init_margin: position.init_margin |> Tai.Utils.Decimal.from(),
      init_margin_req: position.init_margin_req |> Tai.Utils.Decimal.from(),
      maint_margin: position.maint_margin |> Tai.Utils.Decimal.from(),
      maint_margin_req: position.maint_margin_req |> Tai.Utils.Decimal.from(),
      realised_pnl: position.realised_pnl |> Tai.Utils.Decimal.from(),
      unrealised_pnl: position.unrealised_pnl |> Tai.Utils.Decimal.from()
    }
  end
end
