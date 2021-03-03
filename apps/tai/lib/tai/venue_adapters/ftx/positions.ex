defmodule Tai.VenueAdapters.Ftx.Positions do
  alias Tai.VenueAdapters.Ftx.Products

  def positions(venue_id, credential_id, credentials) do
    venue_credentials = to_venue_credentials(credentials)
    show_avg_price = true

    with {:ok, venue_positions} <- ExFtx.Positions.List.get(venue_credentials, show_avg_price) do
      positions  = venue_positions
                   |> Enum.map(&build_position(&1, venue_id, credential_id))
                   |> Enum.filter(& &1)
      {:ok, positions}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp to_venue_credentials(credentials), do: struct(ExFtx.Credentials, credentials)

  def build_position(%ExFtx.Position{entry_price: nil}, _, _), do: nil

  def build_position(venue_position, venue_id, credential_id) do
    %Tai.Trading.Position{
      venue_id: venue_id,
      credential_id: credential_id,
      product_symbol: venue_position.future |> Products.to_symbol(),
      side: venue_position |> to_side(),
      qty: venue_position.net_size |> Tai.Utils.Decimal.cast!(),
      entry_price: venue_position.entry_price |> Tai.Utils.Decimal.cast!(),
      margin_mode: :portfolio
    }
  end

  defp to_side(%_struct{side: "buy"}), do: :long
  defp to_side(%_struct{side: "sell"}), do: :short
end
