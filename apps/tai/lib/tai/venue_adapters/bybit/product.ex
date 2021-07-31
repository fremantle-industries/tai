defmodule Tai.VenueAdapters.Bybit.Product do
  alias ExBybit.Derivatives

  def build(%Derivatives.Symbol{} = symbol, venue_id) do
    type = symbol.name |> to_type()
    expiry = symbol |> to_expiry(type)

    %Tai.Venues.Product{
      venue_id: venue_id,
      symbol: symbol.name |> downcase_and_atom(),
      venue_symbol: symbol.name,
      alias: symbol.alias,
      base: symbol.base_currency |> downcase_and_atom(),
      quote: symbol.quote_currency |> downcase_and_atom(),
      venue_base: symbol.base_currency,
      venue_quote: symbol.quote_currency,
      status: symbol.status |> to_status(),
      type: type,
      expiry: expiry,
      collateral: false,
      price_increment: Decimal.new(symbol.price_filter.tick_size),
      size_increment: Tai.Utils.Decimal.cast!(symbol.lot_size_filter.qty_step),
      min_price: Decimal.new(symbol.price_filter.min_price),
      min_size: Tai.Utils.Decimal.cast!(symbol.lot_size_filter.min_trading_qty),
      max_price: Decimal.new(symbol.price_filter.max_price),
      max_size: Decimal.new(symbol.lot_size_filter.max_trading_qty),
      value: Tai.Utils.Decimal.cast!(symbol.lot_size_filter.qty_step),
      value_side: :quote,
      is_quanto: false,
      is_inverse: to_is_inverse(symbol, type)
    }
  end

  defp downcase_and_atom(str), do: str |> String.downcase() |> String.to_atom()

  defp to_status("Trading"), do: :trading
  defp to_status(_), do: :unknown

  defp to_type(name) do
    case String.match?(name, ~r/.+\d+$/) do
      true -> :future
      false -> :swap
    end
  end

  @expiry_year ~r/.+(?<year>\d{2,2})$/
  @expiry_month_and_day ~r/.+(?<month>\d{2,2})(?<day>\d{2,2})$/
  @expiry_time Time.new!(8, 0, 0, 0)
  defp to_expiry(symbol, type) do
    case type do
      :future ->
        %{"year" => year_str} = Regex.named_captures(@expiry_year, symbol.name)
        %{"month" => month_str, "day" => day_str} = Regex.named_captures(@expiry_month_and_day, symbol.alias)
        {year, _} = "20#{year_str}" |> Integer.parse() # TODO: This is only going to work until 2099
        {month, _} = month_str |> Integer.parse()
        {day, _} = day_str |> Integer.parse()
        date = Date.new!(year, month, day)
        DateTime.new!(date, @expiry_time)

      _ ->
        nil
    end
  end

  defp to_is_inverse(_symbol, :future), do: true
  defp to_is_inverse(%_{quote_currency: "USD"}, :swap),  do: true
  defp to_is_inverse(_, :swap),  do: false
end
