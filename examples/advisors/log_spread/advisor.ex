defmodule Examples.Advisors.LogSpread.Advisor do
  use Tai.Advisor

  require Logger

  alias Tai.Markets.{PriceLevel, Quote}

  def handle_inside_quote(
        feed_id,
        symbol,
        %Quote{bid: %PriceLevel{price: bid_price}, ask: %PriceLevel{price: ask_price}},
        _changes,
        _state
      ) do
    Logger.info(fn ->
      :io_lib.format(
        "[~s,~s] spread: ~f",
        [
          feed_id,
          symbol,
          ask_price - bid_price
        ]
      )
    end)
  end

  def handle_inside_quote(_feed_id, _symbol, _quote, _changes, _state), do: nil
end
