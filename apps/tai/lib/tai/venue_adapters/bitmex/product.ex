defmodule Tai.VenueAdapters.Bitmex.Product do
  @format "{ISO:Extended}"

  def build(%ExBitmex.Instrument{lot_size: nil}, _), do: nil

  def build(instrument, venue_id) do
    symbol = instrument.symbol |> to_symbol
    status = Tai.VenueAdapters.Bitmex.ProductStatus.normalize(instrument.state)
    listing = instrument.listing && Timex.parse!(instrument.listing, @format)
    expiry = instrument.expiry && Timex.parse!(instrument.expiry, @format)
    lot_size = instrument.lot_size |> Decimal.cast()
    tick_size = instrument.tick_size |> Decimal.cast()
    max_order_qty = instrument.max_order_qty && instrument.max_order_qty |> Decimal.cast()
    max_price = instrument.max_price && instrument.max_price |> Decimal.cast()
    maker_fee = instrument.maker_fee && instrument.maker_fee |> Decimal.cast()
    taker_fee = instrument.taker_fee && instrument.taker_fee |> Decimal.cast()

    %Tai.Venues.Product{
      venue_id: venue_id,
      symbol: symbol,
      venue_symbol: instrument.symbol,
      base: instrument.underlying,
      quote: instrument.quote_currency,
      status: status,
      type: :future,
      listing: listing,
      expiry: expiry,
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

  def to_symbol(venue_symbol) do
    venue_symbol
    |> String.downcase()
    |> String.to_atom()
  end

  def from_symbol(symbol) do
    symbol
    |> Atom.to_string()
    |> String.upcase()
  end
end
