defmodule Tai.Markets.OrderBooks.ChangeSet do
  alias __MODULE__

  @type venue_id :: Tai.Venue.id()
  @type product_symbol :: Tai.Venues.Product.symbol()
  @type side :: :bid | :ask
  @type price :: number
  @type size :: number
  @type upsert :: {:upsert, side, price, size}
  @type delete :: {:delete, side, price}
  @type change :: upsert | delete
  @type t :: %ChangeSet{
          venue: venue_id,
          symbol: product_symbol,
          changes: [change],
          last_received_at: DateTime.t(),
          last_venue_timestamp: DateTime.t() | nil
        }

  @enforce_keys ~w(venue symbol changes last_received_at)a
  defstruct ~w(venue symbol changes last_received_at last_venue_timestamp)a
end
