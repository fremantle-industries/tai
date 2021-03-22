defmodule Tai.Trading.OrderStore.Actions.Reject do
  @moduledoc """
  The order was not accepted by the venue. It most likely didn't
  the venue's pass validation criteria.
  """

  @type client_id :: Tai.Trading.Order.client_id()
  @type venue_order_id :: Tai.Trading.Order.venue_order_id()
  @type t :: %__MODULE__{
          client_id: client_id,
          venue_order_id: venue_order_id,
          last_received_at: integer,
          last_venue_timestamp: DateTime.t() | nil
        }

  @enforce_keys ~w[
    client_id
    venue_order_id
    last_received_at
  ]a
  defstruct ~w[
    client_id
    venue_order_id
    last_received_at
    last_venue_timestamp
  ]a
end

defimpl Tai.Trading.OrderStore.Action, for: Tai.Trading.OrderStore.Actions.Reject do
  def required(_), do: :enqueued

  def attrs(action) do
    {:ok, last_received_at} = Tai.Time.monotonic_to_date_time(action.last_received_at)

    %{
      status: :rejected,
      venue_order_id: action.venue_order_id,
      leaves_qty: Decimal.new(0),
      last_received_at: last_received_at,
      last_venue_timestamp: action.last_venue_timestamp
    }
  end
end
