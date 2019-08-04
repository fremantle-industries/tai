defmodule Tai.Trading.OrderStore.Actions.PassivePartialFill do
  @moduledoc """
  An open order has been partially filled
  """

  @type client_id :: Tai.Trading.Order.client_id()
  @type t :: %__MODULE__{
          client_id: client_id,
          cumulative_qty: Decimal.t(),
          leaves_qty: Decimal.t(),
          last_received_at: DateTime.t(),
          last_venue_timestamp: DateTime.t()
        }

  @enforce_keys ~w(client_id cumulative_qty leaves_qty last_received_at last_venue_timestamp)a
  defstruct ~w(client_id cumulative_qty leaves_qty last_received_at last_venue_timestamp)a
end

defimpl Tai.Trading.OrderStore.Action, for: Tai.Trading.OrderStore.Actions.PassivePartialFill do
  def required(_),
    do: ~w(open partially_filled pending_amend pending_cancel amend_error cancel_error)a

  def attrs(action) do
    %{
      status: :partially_filled,
      cumulative_qty: action.cumulative_qty,
      leaves_qty: action.leaves_qty,
      last_received_at: action.last_received_at,
      last_venue_timestamp: action.last_venue_timestamp
    }
  end
end
