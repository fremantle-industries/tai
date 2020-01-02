defmodule Tai.VenueAdapters.Bitmex.Positions do
  def positions(venue_id, credential_id, credentials) do
    venue_credentials = to_venue_credentials(credentials)

    with {:ok, venue_positions, _rate_limit} <-
           ExBitmex.Rest.Position.Index.get(venue_credentials) do
      positions =
        venue_positions
        |> Enum.map(&build(&1, venue_id, credential_id))
        |> Enum.filter(& &1)

      {:ok, positions}
    else
      {:error, reason, _} ->
        {:error, reason}
    end
  end

  defdelegate to_venue_credentials(credentials),
    to: Tai.VenueAdapters.Bitmex.Credentials,
    as: :from

  defp build(%ExBitmex.Position{current_qty: 0}, _, _), do: nil

  defp build(venue_position, venue_id, credential_id) do
    # TODO: This should come from products
    product_symbol =
      venue_position.symbol
      |> String.downcase()
      |> String.to_atom()

    %Tai.Trading.Position{
      venue_id: venue_id,
      credential_id: credential_id,
      product_symbol: product_symbol,
      side: venue_position |> side(),
      qty: venue_position |> qty(),
      entry_price: venue_position |> entry_price(),
      leverage: venue_position |> leverage(),
      margin_mode: venue_position |> margin_mode()
    }
  end

  defp side(%ExBitmex.Position{current_qty: qty}) when qty > 0, do: :long
  defp side(%ExBitmex.Position{current_qty: qty}) when qty < 0, do: :short

  defp qty(%ExBitmex.Position{current_qty: qty}) when qty > 0, do: Decimal.new(qty)
  defp qty(%ExBitmex.Position{current_qty: qty}) when qty < 0, do: Decimal.new(-qty)

  defp entry_price(%ExBitmex.Position{avg_entry_price: p}), do: Decimal.cast(p)

  defp leverage(%ExBitmex.Position{leverage: l}), do: Decimal.new(l)

  defp margin_mode(%ExBitmex.Position{cross_margin: true}), do: :crossed
  defp margin_mode(%ExBitmex.Position{cross_margin: false}), do: :fixed
end
