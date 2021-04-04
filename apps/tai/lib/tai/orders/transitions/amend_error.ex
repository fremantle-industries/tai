defmodule Tai.Orders.Transitions.AmendError do
  @moduledoc """
  There was an error amending the order on the venue
  """

  @type client_id :: Tai.Orders.Order.client_id()
  @type t :: %__MODULE__{
          client_id: client_id,
          reason: term,
          last_received_at: integer
        }

  @enforce_keys ~w[client_id reason last_received_at]a
  defstruct ~w[client_id reason last_received_at]a

  defimpl Tai.Orders.Transition do
    def required(_), do: :pending_amend

    def attrs(transition) do
      {:ok, last_received_at} = Tai.Time.monotonic_to_date_time(transition.last_received_at)

      %{
        status: :amend_error,
        error_reason: transition.reason,
        last_received_at: last_received_at
      }
    end
  end
end
