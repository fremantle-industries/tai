defmodule Tai.VenueAdapters.Bitmex.Products do
  def products(venue_id) do
    with {:ok, instruments, _rate_limit} <-
           ExBitmex.Rest.HTTPClient.non_auth_get("/instrument", %{start: 0, count: 500}) do
      products =
        instruments
        |> Enum.map(&build(&1, venue_id))
        |> Enum.filter(& &1)

      {:ok, products}
    else
      {:error, reason, _} ->
        {:error, reason}
    end
  end

  defp build(%{"lotSize" => nil}, _), do: nil

  defp build(
         %{
           "symbol" => bitmex_symbol,
           "state" => state,
           "lotSize" => lot_size,
           "tickSize" => tick_size,
           "maxOrderQty" => max_order_qty,
           "maxPrice" => max_price,
           "makerFee" => maker_fee,
           "takerFee" => taker_fee
         },
         venue_id
       ) do
    symbol = bitmex_symbol |> String.downcase() |> String.to_atom()
    status = Tai.VenueAdapters.Bitmex.ProductStatus.normalize(state)

    %Tai.Venues.Product{
      venue_id: venue_id,
      symbol: symbol,
      venue_symbol: bitmex_symbol,
      status: status,
      type: :future,
      price_increment: tick_size |> to_decimal,
      size_increment: lot_size |> to_decimal,
      min_price: tick_size |> to_decimal,
      min_size: lot_size |> to_decimal,
      max_price: max_price && max_price |> to_decimal,
      max_size: max_order_qty && max_order_qty |> to_decimal,
      maker_fee: maker_fee && maker_fee |> to_decimal,
      taker_fee: maker_fee && taker_fee |> to_decimal
    }
  end

  defp to_decimal(val) when is_float(val), do: val |> Decimal.from_float()
  defp to_decimal(val), do: val |> Decimal.new()
end
