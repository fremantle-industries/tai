defmodule Tai.Trading.OrderStore.Actions.Fill do
  @moduledoc """
  The order was fully filled and removed from the order book
  """

  @type client_id :: Tai.Trading.Order.client_id()
  @type venue_order_id :: Tai.Trading.Order.venue_order_id()
  @type t :: %__MODULE__{
          client_id: client_id,
          venue_order_id: venue_order_id,
          cumulative_qty: Decimal.t(),
          last_received_at: integer,
          last_venue_timestamp: DateTime.t() | nil
        }

  @enforce_keys ~w[
    client_id
    venue_order_id
    cumulative_qty
    last_received_at
    last_venue_timestamp
  ]a
  defstruct ~w[
    client_id
    venue_order_id
    cumulative_qty
    last_received_at
    last_venue_timestamp
  ]a
end

defimpl Tai.Trading.OrderStore.Action, for: Tai.Trading.OrderStore.Actions.Fill do
  def required(_), do: :enqueued

  def attrs(action) do
    {:ok, last_received_at} = Tai.Time.monotonic_to_date_time(action.last_received_at)

    %{
      status: :filled,
      venue_order_id: action.venue_order_id,
      cumulative_qty: action.cumulative_qty,
      leaves_qty: Decimal.new(0),
      last_received_at: last_received_at,
      last_venue_timestamp: action.last_venue_timestamp
    }
  end
end
