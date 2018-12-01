defmodule Examples.Advisors.LogSpread.Advisor do
  @moduledoc """
  Log the spread between the bid/ask for a product
  """

  use Tai.Advisor

  def handle_inside_quote(
        venue_id,
        product_symbol,
        %Tai.Markets.Quote{
          bid: %Tai.Markets.PriceLevel{},
          ask: %Tai.Markets.PriceLevel{}
        } = market_quote,
        _changes,
        _state
      ) do
    bid_price = market_quote.bid.price |> to_decimal
    ask_price = market_quote.ask.price |> to_decimal
    spread = Decimal.sub(ask_price, bid_price)

    Tai.Events.broadcast(%Examples.Advisors.LogSpread.Events.Spread{
      venue_id: venue_id,
      product_symbol: product_symbol,
      bid_price: bid_price |> Decimal.to_string(:normal),
      ask_price: ask_price |> Decimal.to_string(:normal),
      spread: spread |> Decimal.to_string(:normal)
    })
  end

  def handle_inside_quote(_, _, _, _, _), do: :ok

  defp to_decimal(val) when is_float(val), do: val |> Decimal.from_float()
  defp to_decimal(val), do: val |> Decimal.new()
end
