defmodule Tai.Events.OrderBookSnapshot do
  @type order_book :: Tai.Markets.OrderBook.t()
  @type t :: %Tai.Events.OrderBookSnapshot{
          venue_id: atom,
          symbol: atom
        }

  @enforce_keys [:venue_id, :symbol]
  defstruct [:venue_id, :symbol]
end
