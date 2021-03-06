defmodule Tai.Venues.EstimatedFundingRate do
  alias __MODULE__

  @type t :: %EstimatedFundingRate{
          venue: Tai.Venue.id(),
          venue_product_symbol: Tai.Venues.Product.venue_symbol(),
          product_symbol: Tai.Venues.Product.symbol(),
          next_time: DateTime.t(),
          next_rate: Decimal.t()
        }

  @enforce_keys ~w[
    venue
    venue_product_symbol
    product_symbol
    next_time
    next_rate
  ]a
  defstruct ~w[
    venue
    venue_product_symbol
    product_symbol
    next_time
    next_rate
  ]a

  defimpl Stored.Item do
    @type key :: {Tai.Venue.id(), Tai.Venues.Product.symbol()}
    @type estimated_funding_rate :: Tai.Venues.EstimatedFundingRate.t()

    @spec key(estimated_funding_rate) :: key
    def key(r), do: {r.venue, r.product_symbol}
  end
end
