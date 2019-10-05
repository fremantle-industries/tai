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
          bids: [price_point],
          asks: [price_point],
          last_received_at: DateTime.t() | nil,
          last_venue_timestamp: DateTime.t() | nil
        }

  @enforce_keys ~w(venue_id product_symbol)a
  defstruct venue_id: nil,
            product_symbol: nil,
            bids: [],
            asks: [],
            last_received_at: nil,
            last_venue_timestamp: nil

  def inside_bid(market_quote), do: market_quote.bids |> List.first()
  def inside_ask(market_quote), do: market_quote.asks |> List.first()
end

defimpl Stored.Item, for: Tai.Markets.Quote do
  @type market_quote :: Tai.Markets.Quote.t()

  @spec key(market_quote) :: String.t()
  def key(q), do: "#{q.venue_id}_#{q.product_symbol}"
end
