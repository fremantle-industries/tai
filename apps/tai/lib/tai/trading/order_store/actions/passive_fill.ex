defmodule Tai.Trading.OrderStore.Actions.PassiveFill do
  @moduledoc """
  An open order has been fully filled
  """

  @type client_id :: Tai.Trading.Order.client_id()
  @type t :: %__MODULE__{
          client_id: client_id,
          cumulative_qty: Decimal.t(),
          last_received_at: DateTime.t(),
          last_venue_timestamp: DateTime.t()
        }

  @enforce_keys ~w(client_id cumulative_qty last_received_at last_venue_timestamp)a
  defstruct ~w(client_id cumulative_qty last_received_at last_venue_timestamp)a
end

defimpl Tai.Trading.OrderStore.Action, for: Tai.Trading.OrderStore.Actions.PassiveFill do
  @required ~w(open partially_filled pending_amend pending_cancel amend_error cancel_accepted cancel_error)a
  def required(_), do: @required

  def attrs(action) do
    %{
      status: :filled,
      cumulative_qty: action.cumulative_qty,
      leaves_qty: Decimal.new(0),
      last_received_at: action.last_received_at,
      last_venue_timestamp: action.last_venue_timestamp
    }
  end
end
