defmodule Examples.Advisors.LogSpread.Advisor do
  use Tai.Advisor

  require Logger

  alias Tai.Markets.{PriceLevel, Quote}

  def handle_inside_quote(
        order_book_feed_id,
        symbol,
        %Quote{bid: %PriceLevel{price: bid_price}, ask: %PriceLevel{price: ask_price}},
        _changes,
        _state
      ) do
    Logger.debug(fn ->
      :io_lib.format(
        "[~s,~s] spread: ~f",
        [
          order_book_feed_id,
          symbol,
          ask_price - bid_price
        ]
      )
    end)
  end
end
