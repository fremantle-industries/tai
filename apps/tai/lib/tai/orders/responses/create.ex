defmodule Tai.Orders.Responses.Create do
  @moduledoc """
  Returned from venue adapters for a created order
  """

  @type venue_order_id :: Tai.Orders.Order.venue_order_id()
  @type t :: %__MODULE__{
          id: venue_order_id,
          status: atom,
          original_size: Decimal.t(),
          leaves_qty: Decimal.t(),
          cumulative_qty: Decimal.t(),
          received_at: integer,
          venue_timestamp: DateTime.t() | nil
        }

  @enforce_keys ~w[
    id
    status
    original_size
    leaves_qty
    cumulative_qty
    received_at
  ]a
  defstruct ~w[
    id
    status
    original_size
    leaves_qty
    cumulative_qty
    received_at
    venue_timestamp
  ]a
end
