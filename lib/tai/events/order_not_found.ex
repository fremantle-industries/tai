defmodule Tai.Events.OrderNotFound do
  @type venue_order_id :: Tai.Trading.Order.venue_order_id()
  @type t :: %Tai.Events.OrderNotFound{venue_order_id: venue_order_id}

  @enforce_keys [:venue_order_id]
  defstruct [:venue_order_id]
end
