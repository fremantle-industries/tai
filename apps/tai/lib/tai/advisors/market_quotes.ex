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

  @spec for(t, venue_id, product_symbol) :: market_quote | nil
  def for(market_quotes, venue_id, product_symbol) do
    market_quotes.data |> Map.get({venue_id, product_symbol})
  end
end
