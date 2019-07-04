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
           "symbol" => venue_symbol,
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
    status = Tai.VenueAdapters.Bitmex.ProductStatus.normalize(state)

    %Tai.Venues.Product{
      venue_id: venue_id,
      symbol: venue_symbol |> to_symbol,
      venue_symbol: venue_symbol,
      status: status,
      type: :future,
      price_increment: tick_size |> Decimal.cast(),
      size_increment: lot_size |> Decimal.cast(),
      min_price: tick_size |> Decimal.cast(),
      min_size: lot_size |> Decimal.cast(),
      max_price: max_price && max_price |> Decimal.cast(),
      max_size: max_order_qty && max_order_qty |> Decimal.cast(),
      maker_fee: maker_fee && maker_fee |> Decimal.cast(),
      taker_fee: maker_fee && taker_fee |> Decimal.cast()
    }
  end

  def to_symbol(venue_symbol), do: venue_symbol |> String.downcase() |> String.to_atom()
  def from_symbol(symbol), do: symbol |> Atom.to_string() |> String.upcase()
end
