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
          bid: price_point | nil,
          ask: price_point | nil,
          last_received_at: DateTime.t() | nil,
          last_venue_timestamp: DateTime.t() | nil
        }

  @enforce_keys ~w(
    venue_id
    product_symbol
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

defimpl Stored.Item, for: Tai.Markets.Quote do
  @type market_quote :: Tai.Markets.Quote.t()

  @spec key(market_quote) :: String.t()
  def key(q), do: "#{q.venue_id}_#{q.product_symbol}"
end
