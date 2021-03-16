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
          positions: [position]
        }

  @enforce_keys ~w[venue products accounts positions]a
  defstruct ~w[venue products accounts positions]a
end
