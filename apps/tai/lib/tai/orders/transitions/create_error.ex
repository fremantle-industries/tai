defmodule Tai.Orders.Transitions.CreateError do
  @moduledoc """
  There was an error creating the order on the venue.
  """

  @type client_id :: Tai.Orders.Order.client_id()
  @type t :: %__MODULE__{
          client_id: client_id,
          reason: term,
          last_received_at: integer
        }

  @enforce_keys ~w(client_id reason last_received_at)a
  defstruct ~w(client_id reason last_received_at)a

  defimpl Tai.Orders.Transition do
    def required(_), do: :enqueued

    def attrs(transition) do
      {:ok, last_received_at} = Tai.Time.monotonic_to_date_time(transition.last_received_at)

      %{
        status: :create_error,
        leaves_qty: Decimal.new(0),
        error_reason: transition.reason,
        last_received_at: last_received_at
      }
    end
  end
end
