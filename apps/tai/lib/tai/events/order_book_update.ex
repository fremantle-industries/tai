defmodule Tai.Events.OrderBookUpdate do
  alias __MODULE__

  @type order_book :: Tai.Markets.OrderBook.t()
  @type t :: %OrderBookUpdate{
          venue_id: atom,
          symbol: atom
        }

  @enforce_keys ~w(venue_id symbol)a
  defstruct ~w(venue_id symbol)a
end
