defmodule Tai.Trading.OrderStore.Actions.Open do
  @moduledoc """
  The order has been created on the venue and is passively
  sitting in the order book waiting to be filled
  """

  @type client_id :: Tai.Trading.Order.client_id()
  @type venue_order_id :: Tai.Trading.Order.venue_order_id()
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
end

defimpl Tai.Trading.OrderStore.Action, for: Tai.Trading.OrderStore.Actions.Open do
  def required(_), do: [:enqueued, :create_accepted]

  def attrs(action) do
    {:ok, last_received_at} = Tai.Time.monotonic_to_date_time(action.last_received_at)
    qty = Decimal.add(action.cumulative_qty, action.leaves_qty)

    %{
      status: :open,
      venue_order_id: action.venue_order_id,
      cumulative_qty: action.cumulative_qty,
      leaves_qty: action.leaves_qty,
      qty: qty,
      last_received_at: last_received_at,
      last_venue_timestamp: action.last_venue_timestamp
    }
  end
end
