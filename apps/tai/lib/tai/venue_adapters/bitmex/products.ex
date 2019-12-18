defmodule Tai.VenueAdapters.Bitmex.Products do
  def products(venue_id) do
    with {:ok, instruments, _rate_limit} <-
           ExBitmex.Rest.Instrument.Index.get(%{start: 0, count: 500}) do
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

  defp build(%ExBitmex.Instrument{lot_size: nil}, _), do: nil

  defp build(instrument, venue_id) do
    status = Tai.VenueAdapters.Bitmex.ProductStatus.normalize(instrument.state)
    lot_size = instrument.lot_size |> Decimal.cast()
    tick_size = instrument.tick_size |> Decimal.cast()
    max_order_qty = instrument.max_order_qty && instrument.max_order_qty |> Decimal.cast()
    max_price = instrument.max_price && instrument.max_price |> Decimal.cast()
    maker_fee = instrument.maker_fee && instrument.maker_fee |> Decimal.cast()
    taker_fee = instrument.taker_fee && instrument.taker_fee |> Decimal.cast()

    %Tai.Venues.Product{
      venue_id: venue_id,
      symbol: instrument.symbol |> to_symbol,
      venue_symbol: instrument.symbol,
      base: instrument.underlying,
      quote: instrument.quote_currency,
      status: status,
      type: :future,
      price_increment: tick_size,
      size_increment: lot_size,
      min_price: tick_size,
      min_size: Decimal.new(1),
      max_price: max_price,
      max_size: max_order_qty,
      value: lot_size,
      is_quanto: instrument.is_quanto,
      is_inverse: instrument.is_inverse,
      maker_fee: maker_fee,
      taker_fee: taker_fee
    }
  end

  def to_symbol(venue_symbol), do: venue_symbol |> String.downcase() |> String.to_atom()
  def from_symbol(symbol), do: symbol |> Atom.to_string() |> String.upcase()
end
