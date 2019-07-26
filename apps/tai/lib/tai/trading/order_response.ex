defmodule Tai.Trading.OrderResponse do
  @moduledoc """
  Return from venue adapters when creating or canceling an order
  """

  @type t :: %Tai.Trading.OrderResponse{
          id: String.t(),
          status: atom,
          time_in_force: atom,
          original_size: Decimal.t(),
          leaves_qty: Decimal.t(),
          cumulative_qty: Decimal.t(),
          timestamp: DateTime.t() | nil
        }

  @enforce_keys [
    :id,
    :status,
    :time_in_force,
    :original_size,
    :cumulative_qty
  ]
  defstruct [
    :id,
    :status,
    :time_in_force,
    :original_size,
    :leaves_qty,
    :cumulative_qty,
    :timestamp
  ]
end
