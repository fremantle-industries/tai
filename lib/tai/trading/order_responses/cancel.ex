defmodule Tai.Trading.OrderResponses.Cancel do
  @moduledoc """
  Return from venue adapters when canceling an order
  """

  @type t :: %Tai.Trading.OrderResponses.Cancel{
          id: String.t(),
          status: atom,
          leaves_qty: Decimal.t(),
          timestamp: DateTime.t() | nil
        }

  @enforce_keys [
    :id,
    :status,
    :leaves_qty
  ]
  defstruct [
    :id,
    :status,
    :leaves_qty,
    :timestamp
  ]
end
