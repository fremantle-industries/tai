defmodule Tai.VenueAdapters.OkEx.Products do
  alias ExOkex.{Futures, Swap, Spot}

  def products(venue_id) do
    with {:ok, future_instruments} <- Futures.Public.instruments(),
         {:ok, swap_instruments} <- Swap.Public.instruments(),
         {:ok, spot_instruments} <- Spot.Public.instruments() do
      future_products = future_instruments |> Enum.map(&build(&1, venue_id))
      swap_products = swap_instruments |> Enum.map(&build(&1, venue_id))
      spot_products = spot_instruments |> Enum.map(&build(&1, venue_id))
      products = future_products ++ swap_products ++ spot_products
      {:ok, products}
    end
  end

  defp build(%Futures.Instrument{} = instrument, venue_id) do
    build_product(
      type: :future,
      venue_id: venue_id,
      venue_symbol: instrument.instrument_id,
      base: instrument.underlying_index,
      quote: instrument.quote_currency,
      venue_price_increment: instrument.tick_size,
      venue_size_increment: instrument.trade_increment
    )
  end

  defp build(%Swap.Instrument{} = instrument, venue_id) do
    build_product(
      type: :swap,
      venue_id: venue_id,
      venue_symbol: instrument.instrument_id,
      base: instrument.coin,
      quote: instrument.quote_currency,
      venue_price_increment: instrument.tick_size,
      venue_size_increment: instrument.size_increment
    )
  end

  defp build(%Spot.Instrument{} = instrument, venue_id) do
    build_product(
      type: :spot,
      venue_id: venue_id,
      venue_symbol: instrument.instrument_id,
      base: instrument.base_currency,
      quote: instrument.quote_currency,
      venue_price_increment: instrument.tick_size,
      venue_size_increment: instrument.size_increment,
      venue_min_size: instrument.min_size
    )
  end

  defp build_product(args) do
    venue_symbol = Keyword.fetch!(args, :venue_symbol)
    venue_size_increment = Keyword.fetch!(args, :venue_size_increment)

    symbol = venue_symbol |> to_symbol()
    price_increment = args |> Keyword.fetch!(:venue_price_increment) |> Decimal.cast()
    size_increment = venue_size_increment |> Decimal.cast()
    min_size = args |> Keyword.get(:min_size, venue_size_increment) |> Decimal.cast()

    %Tai.Venues.Product{
      venue_id: Keyword.fetch!(args, :venue_id),
      symbol: symbol,
      venue_symbol: venue_symbol,
      base: Keyword.fetch!(args, :base),
      quote: Keyword.fetch!(args, :quote),
      status: :trading,
      type: Keyword.fetch!(args, :type),
      price_increment: price_increment,
      size_increment: size_increment,
      min_price: price_increment,
      min_size: min_size
    }
  end

  def to_symbol(instrument_id) do
    instrument_id |> String.replace("-", "_") |> String.downcase() |> String.to_atom()
  end

  def from_symbol(symbol) do
    symbol |> Atom.to_string() |> String.replace("_", "-") |> String.upcase()
  end
end
