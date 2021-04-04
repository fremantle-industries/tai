defmodule Tai.Orders.Transitions.PassiveCancel do
  @moduledoc """
  An open order has been successfully canceled
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
    @required ~w(
      create_accepted
      rejected
      open
      partially_filled
      filled expired
      pending_amend
      amend
      amend_error
      pending_cancel
      cancel_accepted
    )a

    def required(_), do: @required

    def attrs(transition) do
      {:ok, last_received_at} = Tai.Time.monotonic_to_date_time(transition.last_received_at)

      %{
        status: :canceled,
        leaves_qty: Decimal.new(0),
        last_received_at: last_received_at,
        last_venue_timestamp: transition.last_venue_timestamp
      }
    end
  end
end
