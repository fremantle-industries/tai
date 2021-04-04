defmodule Tai.Orders.Transitions.Amend do
  @moduledoc """
  The order was successfully amended on the venue
  """

  @type client_id :: Tai.Orders.Order.client_id()
  @type t :: %__MODULE__{
          client_id: client_id,
          price: Decimal.t(),
          leaves_qty: Decimal.t(),
          last_received_at: integer,
          last_venue_timestamp: DateTime.t()
        }

  @enforce_keys ~w[client_id price leaves_qty last_received_at last_venue_timestamp]a
  defstruct ~w[client_id price leaves_qty last_received_at last_venue_timestamp]a

  defimpl Tai.Orders.Transition do
    def required(_), do: [:partially_filled, :pending_amend]

    def attrs(transition) do
      {:ok, last_received_at} = Tai.Time.monotonic_to_date_time(transition.last_received_at)

      %{
        status: :open,
        price: transition.price,
        leaves_qty: transition.leaves_qty,
        last_received_at: last_received_at,
        last_venue_timestamp: transition.last_venue_timestamp
      }
    end
  end
end
