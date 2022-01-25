defmodule Tai.Advisors.MarketMap do
  @type venue :: Tai.Venue.id()
  @type product_symbol :: Tai.Venues.Product.symbol()
  @type market_quote :: Tai.Markets.Quote.t()
  @type trade :: Tai.Markets.Trade.t()
  @type t :: %__MODULE__{
          data: %{
            {venue, product_symbol} => market_quote | trade
          }
        }

  @enforce_keys ~w[data]a
  defstruct ~w[data]a

  @spec for(t, venue, product_symbol) :: {:ok, market_quote | trade} | {:error, :not_found}
  def for(market_map, venue_id, product_symbol) do
    market_map.data
    |> Map.get({venue_id, product_symbol})
    |> case do
      nil -> {:error, :not_found}
      quote_or_trade -> {:ok, quote_or_trade}
    end
  end

  @spec each(t, (market_quote | trade -> term)) :: :ok
  def each(market_map, callback) do
    market_map.data
    |> Enum.each(fn {_k, q} -> callback.(q) end)
  end

  @spec map(t, (market_quote | trade -> term)) :: [term]
  def map(market_map, callback) do
    market_map.data
    |> Enum.map(fn {_k, q} -> callback.(q) end)
  end

  @spec flat_map(t, (market_quote | trade -> term)) :: [term]
  def flat_map(market_map, callback) do
    market_map.data
    |> Enum.flat_map(fn {_k, q} -> callback.(q) end)
  end
end
