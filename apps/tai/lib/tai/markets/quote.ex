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

  @spec inside_bid(t) :: price_point | nil
  def inside_bid(market_quote), do: market_quote.bids |> List.first()

  @spec inside_ask(t) :: price_point | nil
  def inside_ask(market_quote), do: market_quote.asks |> List.first()

  @spec mid_price(t) :: {:ok, Decimal.t()} | {:error, :no_inside_bid | :no_inside_ask}
  @spec mid_price(bid :: price_point, ask :: price_point) ::
          {:ok, Decimal.t()} | {:error, :no_inside_bid | :no_inside_ask}
  def mid_price(%Quote{} = market_quote) do
    bid = market_quote |> inside_bid
    ask = market_quote |> inside_ask
    mid_price(bid, ask)
  end

  @two Decimal.new(2)
  def mid_price(%PricePoint{} = bid, %PricePoint{} = ask) do
    ask_price = Decimal.cast(ask.price)
    bid_price = Decimal.cast(bid.price)

    mid =
      ask_price
      |> Decimal.sub(bid_price)
      |> Decimal.div(@two)
      |> Decimal.add(bid_price)

    {:ok, mid}
  end

  def mid_price(nil, %PricePoint{}), do: {:error, :no_inside_bid}
  def mid_price(%PricePoint{}, nil), do: {:error, :no_inside_ask}
end

defimpl Stored.Item, for: Tai.Markets.Quote do
  @type market_quote :: Tai.Markets.Quote.t()
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type product_symbol :: Tai.Venues.Product.symbol()

  @spec key(market_quote) :: {venue_id, product_symbol}
  def key(q), do: {q.venue_id, q.product_symbol}
end
