defmodule Tai.VenueAdapters.OkEx.Product do
  alias ExOkex.{Futures, Swap, Spot}

  @iso_date_format "{ISOdate}"
  @zone "Etc/UTC"
  def build(%Futures.Instrument{} = instrument, venue_id) do
    listing = instrument.listing |> Timex.parse!(@iso_date_format) |> DateTime.from_naive!(@zone)
    expiry = instrument.delivery |> Timex.parse!(@iso_date_format) |> DateTime.from_naive!(@zone)

    build_product(
      type: :future,
      venue_id: venue_id,
      venue_symbol: instrument.instrument_id,
      alias: instrument.alias,
      base: instrument.underlying_index,
      quote: instrument.quote_currency,
      listing: listing,
      expiry: expiry,
      venue_price_increment: instrument.tick_size,
      venue_size_increment: instrument.trade_increment,
      value: instrument.contract_val,
      is_quanto: false,
      is_inverse: true
    )
  end

  @iso_extended_format "{ISO:Extended}"
  def build(%Swap.Instrument{} = instrument, venue_id) do
    listing = Timex.parse!(instrument.listing, @iso_extended_format)

    build_product(
      type: :swap,
      venue_id: venue_id,
      venue_symbol: instrument.instrument_id,
      base: instrument.coin,
      quote: instrument.quote_currency,
      listing: listing,
      venue_price_increment: instrument.tick_size,
      venue_size_increment: instrument.size_increment,
      value: instrument.contract_val,
      is_quanto: false,
      is_inverse: true
    )
  end

  def build(%Spot.Instrument{} = instrument, venue_id) do
    build_product(
      type: :spot,
      venue_id: venue_id,
      venue_symbol: instrument.instrument_id,
      base: instrument.base_currency,
      quote: instrument.quote_currency,
      venue_price_increment: instrument.tick_size,
      venue_size_increment: instrument.size_increment,
      venue_min_size: instrument.min_size,
      value: 1,
      is_quanto: false,
      is_inverse: false
    )
  end

  def to_symbol(instrument_id) do
    instrument_id
    |> String.replace("-", "_")
    |> String.downcase()
    |> String.to_atom()
  end

  def from_symbol(symbol) do
    symbol
    |> Atom.to_string()
    |> String.replace("_", "-")
    |> String.upcase()
  end

  defp build_product(args) do
    venue_symbol = Keyword.fetch!(args, :venue_symbol)
    product_alias = args |> Keyword.get(:alias)
    venue_size_increment = Keyword.fetch!(args, :venue_size_increment)

    symbol = venue_symbol |> to_symbol()
    price_increment = args |> Keyword.fetch!(:venue_price_increment) |> Decimal.cast()
    size_increment = venue_size_increment |> Decimal.cast()
    min_size = args |> Keyword.get(:venue_min_size, venue_size_increment) |> Decimal.cast()
    value = args |> Keyword.fetch!(:value) |> Decimal.cast()
    listing = args |> Keyword.get(:listing)
    expiry = args |> Keyword.get(:expiry)

    %Tai.Venues.Product{
      venue_id: Keyword.fetch!(args, :venue_id),
      symbol: symbol,
      venue_symbol: venue_symbol,
      alias: product_alias,
      base: Keyword.fetch!(args, :base),
      quote: Keyword.fetch!(args, :quote),
      status: :trading,
      type: Keyword.fetch!(args, :type),
      listing: listing,
      expiry: expiry,
      price_increment: price_increment,
      size_increment: size_increment,
      min_price: price_increment,
      min_size: min_size,
      value: value,
      is_quanto: Keyword.fetch!(args, :is_quanto),
      is_inverse: Keyword.fetch!(args, :is_inverse)
    }
  end
end
