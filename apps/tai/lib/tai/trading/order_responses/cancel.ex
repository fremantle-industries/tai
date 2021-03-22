defmodule Tai.Trading.OrderResponses.Cancel do
  @moduledoc """
  Return from venue adapters when the order was canceled
  """

  @type venue_order_id :: Tai.Trading.Order.venue_order_id()
  @type t :: %Tai.Trading.OrderResponses.Cancel{
          id: venue_order_id,
          status: atom,
          leaves_qty: Decimal.t(),
          received_at: integer,
          venue_timestamp: DateTime.t() | nil
        }

  @enforce_keys ~w[
    id
    status
    leaves_qty
    received_at
  ]a
  defstruct ~w[
    id
    status
    leaves_qty
    received_at
    venue_timestamp
  ]a
end
