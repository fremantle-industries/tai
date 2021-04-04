defmodule Tai.Orders.Transitions.AcceptCancel do
  @moduledoc """
  The cancel request has been accepted by the venue. The result of the canceled
  order is received in the stream.
  """

  @type client_id :: Tai.Orders.Order.client_id()
  @type t :: %__MODULE__{
          client_id: client_id,
          last_received_at: integer,
          last_venue_timestamp: DateTime.t()
        }

  @enforce_keys ~w[client_id last_received_at last_venue_timestamp]a
  defstruct ~w[client_id last_received_at last_venue_timestamp]a

  defimpl Tai.Orders.Transition do
    def required(_), do: :pending_cancel

    def attrs(transition) do
      {:ok, last_received_at} = Tai.Time.monotonic_to_date_time(transition.last_received_at)

      %{
        status: :cancel_accepted,
        last_received_at: last_received_at,
        last_venue_timestamp: transition.last_venue_timestamp
      }
    end
  end
end
