defmodule Tai.Venues.Stream do
  alias __MODULE__

  @type venue :: Tai.Venue.t()
  @type product :: Tai.Venues.Product.t()
  @type account :: Tai.Venues.Account.t()
  @type position :: Tai.Trading.Position.t()
  @type t :: %Stream{
          venue: venue,
          products: [product],
          accounts: [account],
          positions: [position],
          funding_rates_enabled: boolean,
          funding_rate_poll_interval: non_neg_integer
        }

  @enforce_keys ~w[
    venue
    products
    accounts
    positions
    funding_rates_enabled
    funding_rate_poll_interval
  ]a
  defstruct ~w[
    venue
    products
    accounts
    positions
    funding_rates_enabled
    funding_rate_poll_interval
  ]a
end
