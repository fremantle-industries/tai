defmodule Tai.VenueAdapters.Deribit.Product do
  @time_unit :millisecond

  def build(instrument, venue_id) do
    symbol = instrument.instrument_name |> to_symbol
    status = instrument |> to_status
    type = instrument |> to_type
    listing = Timex.from_unix(instrument.creation_timestamp, @time_unit)
    expiry = Timex.from_unix(instrument.expiration_timestamp, @time_unit)
    min_trade_amount = instrument.min_trade_amount |> Tai.Utils.Decimal.cast!(:normalize)
    tick_size = instrument.tick_size |> Tai.Utils.Decimal.cast!()
    contract_size = instrument.contract_size |> Tai.Utils.Decimal.cast!(:normalize)
    maker_fee = instrument.maker_commission |> Tai.Utils.Decimal.cast!()
    taker_fee = instrument.taker_commission |> Tai.Utils.Decimal.cast!()

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
      collateral: false,
      price_increment: tick_size,
      size_increment: min_trade_amount,
      min_price: tick_size,
      min_size: Decimal.new(1),
      value: contract_size,
      value_side: :quote,
      is_quanto: false,
      is_inverse: true,
      maker_fee: maker_fee,
      taker_fee: taker_fee,
      option_type: instrument.option_type |> option_type,
      strike: instrument.strike |> strike_price
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

  defp option_type("put"), do: :put
  defp option_type("call"), do: :call
  defp option_type(_), do: nil

  defp strike_price(price) when is_number(price) do
    price
    |> Tai.Utils.Decimal.cast!(:normalize)
    |> Decimal.to_string(:normal)
    |> Decimal.new()
  end

  defp strike_price(_), do: nil
end
