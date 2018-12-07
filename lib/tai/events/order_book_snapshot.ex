defmodule Tai.Events.OrderBookSnapshot do
  @type order_book :: Tai.Markets.OrderBook.t()
  @type t :: %Tai.Events.OrderBookSnapshot{
          venue_id: atom,
          symbol: atom,
          snapshot: order_book
        }

  @enforce_keys [:venue_id, :symbol, :snapshot]
  defstruct [:venue_id, :symbol, :snapshot]
end
