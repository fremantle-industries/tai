defmodule Examples.Advisors.LogSpread.Events.Spread do
  @type t :: %Examples.Advisors.LogSpread.Events.Spread{
          venue_id: atom,
          product_symbol: atom,
          bid_price: String.t(),
          ask_price: String.t(),
          spread: String.t()
        }

  @enforce_keys [
    :venue_id,
    :product_symbol,
    :bid_price,
    :ask_price,
    :spread
  ]
  defstruct [
    :venue_id,
    :product_symbol,
    :bid_price,
    :ask_price,
    :spread
  ]
end
