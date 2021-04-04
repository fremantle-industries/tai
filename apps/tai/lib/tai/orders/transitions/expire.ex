defmodule Tai.Orders.Transitions.Expire do
  @moduledoc """
  The order was not filled or partially filled and removed from the order book
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
    def required(_), do: :enqueued

    def attrs(transition) do
      {:ok, last_received_at} = Tai.Time.monotonic_to_date_time(transition.last_received_at)

      %{
        status: :expired,
        venue_order_id: transition.venue_order_id,
        cumulative_qty: transition.cumulative_qty,
        leaves_qty: transition.leaves_qty,
        last_received_at: last_received_at,
        last_venue_timestamp: transition.last_venue_timestamp
      }
    end
  end
end
