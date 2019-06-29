defmodule Tai.Trading.OrderStore.Actions.PassiveCancel do
  @moduledoc """
  An open order has been successfully canceled
  """

  @type client_id :: Tai.Trading.Order.client_id()
  @type t :: %__MODULE__{
          client_id: client_id,
          last_received_at: DateTime.t(),
          last_venue_timestamp: DateTime.t()
        }

  @enforce_keys ~w(client_id last_received_at last_venue_timestamp)a
  defstruct ~w(client_id last_received_at last_venue_timestamp)a
end

defimpl Tai.Trading.OrderStore.Action, for: Tai.Trading.OrderStore.Actions.PassiveCancel do
  def required(_),
    do: ~w(open expired filled pending_amend amend amend_error pending_cancel cancel_accepted)a

  def attrs(action) do
    %{
      status: :canceled,
      leaves_qty: Decimal.new(0),
      last_received_at: action.last_received_at,
      last_venue_timestamp: action.last_venue_timestamp
    }
  end
end
