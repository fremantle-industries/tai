defmodule Tai.VenueAdapters.Deribit.Product do
  @time_unit :millisecond

  def build(instrument, venue_id) do
    symbol = instrument.instrument_name |> to_symbol
    status = instrument |> to_status
    type = instrument |> to_type
    listing = Timex.from_unix(instrument.creation_timestamp, @time_unit)
    expiry = Timex.from_unix(instrument.expiration_timestamp, @time_unit)
    min_trade_amount = instrument.min_trade_amount |> Decimal.cast() |> Decimal.reduce()
    tick_size = instrument.tick_size |> Decimal.cast()
    contract_size = instrument.contract_size |> Decimal.cast() |> Decimal.reduce()
    maker_fee = instrument.maker_commission |> Decimal.cast()
    taker_fee = instrument.taker_commission |> Decimal.cast()

    %Tai.Venues.Product{
      venue_id: venue_id,
      symbol: symbol,
      venue_symbol: instrument.instrument_name,
      base: instrument.base_currency |> downcase_and_atom(),
      quote: instrument.quote_currency |> downcase_and_atom(),
      venue_base: instrument.base_currency,
      venue_quote: instrument.quote_currency,
      status: status,
      type: type,
      listing: listing,
      expiry: expiry,
      price_increment: tick_size,
      size_increment: min_trade_amount,
      min_price: tick_size,
      min_size: Decimal.new(1),
      value: contract_size,
      is_quanto: false,
      is_inverse: true,
      maker_fee: maker_fee,
      taker_fee: taker_fee
    }
  end

  def to_symbol(venue_symbol) do
    venue_symbol
    |> String.replace("-", "_")
    |> downcase_and_atom()
  end

  def from_symbol(symbol) do
    symbol
    |> Atom.to_string()
    |> String.upcase()
  end

  defp downcase_and_atom(str), do: str |> String.downcase() |> String.to_atom()

  defp to_status(%ExDeribit.Instrument{is_active: true}), do: :trading
  defp to_status(%ExDeribit.Instrument{is_active: false}), do: :halt

  defp to_type(%ExDeribit.Instrument{kind: "option"}), do: :option

  defp to_type(%ExDeribit.Instrument{kind: "future", instrument_name: instrument_name}) do
    instrument_name
    |> String.split("-")
    |> Enum.reverse()
    |> case do
      ["PERPETUAL" | _] -> :swap
      _ -> :future
    end
  end
end
