defmodule Examples.LogSpread.Advisor do
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
        state
      ) do
    bid_price = market_quote.bid.price |> Decimal.cast()
    ask_price = market_quote.ask.price |> Decimal.cast()
    spread = Decimal.sub(ask_price, bid_price)

    Tai.Events.info(%Examples.LogSpread.Events.Spread{
      venue_id: venue_id,
      product_symbol: product_symbol,
      bid_price: bid_price |> Decimal.to_string(:normal),
      ask_price: ask_price |> Decimal.to_string(:normal),
      spread: spread |> Decimal.to_string(:normal)
    })

    {:ok, state.store}
  end

  def handle_inside_quote(_, _, _, _, state), do: {:ok, state.store}
end
