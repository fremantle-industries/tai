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
end
