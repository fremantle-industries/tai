defmodule Tai.Orders.Transitions.Open do
  @moduledoc """
  The order has been created on the venue and is passively
  sitting in the order book waiting to be filled
  """

  @type client_id :: Tai.Orders.Order.client_id()
  @type venue_order_id :: Tai.Orders.Order.venue_order_id()
  @type t :: %__MODULE__{
          client_id: client_id,
          venue_order_id: venue_order_id,
          cumulative_qty: Decimal.t(),
          leaves_qty: Decimal.t(),
          last_received_at: integer,
          last_venue_timestamp: DateTime.t() | nil
        }

  @enforce_keys ~w[
    client_id
    venue_order_id
    cumulative_qty
    leaves_qty
    last_received_at
    last_venue_timestamp
  ]a
  defstruct ~w[
    client_id
    venue_order_id
    cumulative_qty
    leaves_qty
    last_received_at
    last_venue_timestamp
  ]a

  defimpl Tai.Orders.Transition do
    def required(_), do: [:enqueued, :create_accepted]

    def attrs(transition) do
      {:ok, last_received_at} = Tai.Time.monotonic_to_date_time(transition.last_received_at)
      qty = Decimal.add(transition.cumulative_qty, transition.leaves_qty)

      %{
        status: :open,
        venue_order_id: transition.venue_order_id,
        cumulative_qty: transition.cumulative_qty,
        leaves_qty: transition.leaves_qty,
        qty: qty,
        last_received_at: last_received_at,
        last_venue_timestamp: transition.last_venue_timestamp
      }
    end
  end
end
