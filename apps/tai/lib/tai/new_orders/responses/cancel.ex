defmodule Tai.NewOrders.Responses.Cancel do
  @moduledoc """
  Return from venue adapters when the order was canceled
  """

  @type venue_order_id :: Tai.NewOrders.Order.venue_order_id()
  @type t :: %__MODULE__{
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
