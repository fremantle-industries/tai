defmodule Examples.LogSpread.Advisor do
  @moduledoc """
  Log the spread between the bid/ask for a product
  """

  use Tai.Advisor

  def handle_event(
        # wait until we have a quote with price points for both sides of the order book
        %Tai.Markets.Quote{bids: [inside_bid | _], asks: [inside_ask | _]} = market_quote,
        state
      ) do
    bid_price = inside_bid.price |> Decimal.cast()
    bid_size = inside_bid.size |> Decimal.cast()
    ask_price = inside_ask.price |> Decimal.cast()
    ask_size = inside_ask.size |> Decimal.cast()
    spread = Decimal.sub(ask_price, bid_price)

    %Examples.LogSpread.Events.Spread{
      venue_id: market_quote.venue_id,
      product_symbol: market_quote.product_symbol,
      bid_price: bid_price,
      bid_size: bid_size,
      ask_price: ask_price,
      ask_size: ask_size,
      spread: spread
    }
    |> Tai.Events.info()

    {:ok, state.store}
  end

  # ignore quotes that don't have both sides of the order book
  def handle_event(_, state), do: {:ok, state.store}
end
