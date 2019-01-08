defmodule Tai.Trading.OrderResponse do
  @moduledoc """
  Returned from creating or amending an order
  """

  @type t :: %Tai.Trading.OrderResponse{
          id: String.t(),
          status: atom,
          time_in_force: atom,
          original_size: Decimal.t(),
          cumulative_qty: Decimal.t(),
          remaining_qty: Decimal.t(),
          timestamp: DateTime.t() | nil
        }

  @enforce_keys [
    :id,
    :status,
    :time_in_force,
    :original_size,
    :cumulative_qty
    # :remaining_qty
  ]
  defstruct [
    :id,
    :status,
    :time_in_force,
    :original_size,
    :cumulative_qty,
    :remaining_qty,
    :timestamp
  ]
end
