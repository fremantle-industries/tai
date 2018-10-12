defmodule Examples.Advisors.LogSpread.Advisor do
  @moduledoc """
  Log the spread between the bid/ask for a product
  """

  use Tai.Advisor

  require Logger

  def handle_inside_quote(
        feed_id,
        symbol,
        %Tai.Markets.Quote{
          bid: %Tai.Markets.PriceLevel{price: bp},
          ask: %Tai.Markets.PriceLevel{price: ap}
        },
        _changes,
        _state
      ) do
    bid_price = Decimal.new(bp)
    ask_price = Decimal.new(ap)
    spread = Decimal.sub(ask_price, bid_price)

    "[spread:~s,~s,~s,~s,~s]"
    |> :io_lib.format([
      feed_id,
      symbol,
      spread |> Decimal.to_string(:normal),
      bid_price |> Decimal.to_string(:normal),
      ask_price |> Decimal.to_string(:normal)
    ])
    |> Logger.info()
  end

  def handle_inside_quote(_feed_id, _symbol, _quote, _changes, _state), do: nil
end
