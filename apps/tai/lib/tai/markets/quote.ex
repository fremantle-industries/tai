defmodule Tai.Markets.Quote do
  @moduledoc """
  Represents a bid & ask price level row in the order book
  """

  alias Tai.Markets.{PriceLevel, Quote}

  @type price_level :: PriceLevel.t()
  @type t :: %Quote{
          venue_id: atom,
          product_symbol: atom,
          bid: price_level,
          ask: price_level,
          last_received_at: DateTime.t() | nil,
          last_venue_timestamp: DateTime.t() | nil
        }

  @enforce_keys ~w(
    venue_id
    product_symbol
    bid
    ask
  )a
  defstruct ~w(
    venue_id
    product_symbol
    bid
    ask
    last_received_at
    last_venue_timestamp
  )a
end
