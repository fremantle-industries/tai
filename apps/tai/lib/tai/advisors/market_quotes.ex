defmodule Tai.Advisors.MarketQuotes do
  alias Tai.Advisors.MarketQuotes

  @type venue_id :: Tai.Venue.id()
  @type product_symbol :: Tai.Venues.Product.symbol()
  @type market_quote :: Tai.Markets.Quote.t()
  @type t :: %MarketQuotes{
          data: %{
            {venue_id, product_symbol} => market_quote
          }
        }

  @enforce_keys ~w(data)a
  defstruct ~w(data)a

  @spec for(t, venue_id, product_symbol) :: {:ok, market_quote} | {:error, :not_found}
  def for(market_quotes, venue_id, product_symbol) do
    market_quotes.data
    |> Map.get({venue_id, product_symbol})
    |> case do
      nil -> {:error, :not_found}
      market_quote -> {:ok, market_quote}
    end
  end

  @spec each(t, (market_quote -> term)) :: :ok
  def each(market_quotes, callback) do
    market_quotes.data
    |> Enum.each(fn {_k, q} -> callback.(q) end)
  end

  @spec map(t, (market_quote -> term)) :: [term]
  def map(market_quotes, callback) do
    market_quotes.data
    |> Enum.map(fn {_k, q} -> callback.(q) end)
  end

  @spec flat_map(t, (market_quote -> term)) :: [term]
  def flat_map(market_quotes, callback) do
    market_quotes.data
    |> Enum.flat_map(fn {_k, q} -> callback.(q) end)
  end
end
