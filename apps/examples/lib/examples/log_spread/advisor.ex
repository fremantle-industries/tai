defmodule Examples.LogSpread.Advisor do
  @moduledoc """
  Log the spread between the bid/ask for a product
  """

  use Tai.Advisor

  def handle_event(
        # wait until we have a quote with price points for both sides of the order book
        %Tai.Markets.Quote{
          bid: %Tai.Markets.PricePoint{},
          ask: %Tai.Markets.PricePoint{}
        } = market_quote,
        state
      ) do
    bid_price = market_quote.bid.price |> Decimal.cast()
    ask_price = market_quote.ask.price |> Decimal.cast()
    spread = Decimal.sub(ask_price, bid_price)

    %Examples.LogSpread.Events.Spread{
      venue_id: market_quote.venue_id,
      product_symbol: market_quote.product_symbol,
      bid_price: bid_price |> Decimal.to_string(:normal),
      ask_price: ask_price |> Decimal.to_string(:normal),
      spread: spread |> Decimal.to_string(:normal)
    }
    |> Tai.Events.info()

    {:ok, state.store}
  end

  # ignore quotes that don't have both sides of the order book
  def handle_event(_, state), do: {:ok, state.store}
end
