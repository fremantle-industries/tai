defmodule Tai.Markets.Quote do
  @moduledoc """
  Represents a bid & ask price level row in the order book
  """

  alias Tai.Markets

  @type price_level :: Markets.PriceLevel.t()
  @type t :: %Markets.Quote{
          venue_id: atom,
          product_symbol: atom,
          bid: price_level,
          ask: price_level
        }

  @enforce_keys [
    :venue_id,
    :product_symbol,
    :bid,
    :ask
  ]
  defstruct [
    :venue_id,
    :product_symbol,
    :bid,
    :ask
  ]
end
