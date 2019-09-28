defmodule Tai.Markets.Quote do
  @moduledoc """
  Represents the inside bid & ask price point within the order book
  """

  alias __MODULE__
  alias Tai.Markets.PricePoint

  @type price_point :: PricePoint.t()
  @type t :: %Quote{
          venue_id: atom,
          product_symbol: atom,
          bid: price_point,
          ask: price_point,
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
