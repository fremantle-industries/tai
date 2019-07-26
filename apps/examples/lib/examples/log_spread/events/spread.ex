defmodule Examples.LogSpread.Events.Spread do
  alias __MODULE__

  @type t :: %Spread{
          venue_id: atom,
          product_symbol: atom,
          bid_price: String.t(),
          ask_price: String.t(),
          spread: String.t()
        }

  @enforce_keys ~w(
    venue_id
    product_symbol
    bid_price
    ask_price
    spread
  )a
  defstruct ~w(
    venue_id
    product_symbol
    bid_price
    ask_price
    spread
  )a
end
