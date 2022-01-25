defmodule Tai.Venues.Stream do
  alias __MODULE__

  @type venue :: Tai.Venue.t()
  @type product :: Tai.Venues.Product.t()
  @type account :: Tai.Venues.Account.t()
  @type position :: Tai.Trading.Position.t()
  @type t :: %Stream{
          venue: venue,
          markets: [product],
          accounts: [account],
          positions: [position]
        }

  @enforce_keys ~w[venue markets accounts positions]a
  defstruct ~w[venue markets accounts positions]a
end
