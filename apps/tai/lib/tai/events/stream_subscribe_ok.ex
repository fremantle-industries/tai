defmodule Tai.Events.StreamSubscribeOk do
  alias __MODULE__

  @type venue_id :: Tai.Venue.id()
  @type venue_symbol :: Tai.Venues.Product.venue_symbol()
  @type t :: %StreamSubscribeOk{
          venue: venue_id,
          channel_name: String.t(),
          venue_symbols: [venue_symbol],
          received_at: DateTime.t()
        }

  @enforce_keys ~w(venue channel_name venue_symbols received_at)a
  defstruct ~w(venue channel_name venue_symbols received_at)a
end
