defmodule Tai.Venues.FundingRate do
  alias __MODULE__

  @type t :: %FundingRate{
          venue: Tai.Venue.id(),
          venue_product_symbol: Tai.Venues.Product.venue_symbol(),
          product_symbol: Tai.Venues.Product.symbol(),
          time: DateTime.t(),
          rate: Decimal.t()
        }

  @enforce_keys ~w[
    venue
    venue_product_symbol
    product_symbol
    time
    rate
  ]a
  defstruct ~w[
    venue
    venue_product_symbol
    product_symbol
    time
    rate
  ]a

  defimpl Stored.Item do
    @type key :: {Tai.Venue.id(), Tai.Venues.Product.symbol()}
    @type funding_rate :: Tai.Venues.FundingRate.t()

    @spec key(funding_rate) :: key
    def key(r), do: {r.venue, r.product_symbol}
  end
end
