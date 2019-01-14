defmodule Tai.Trading.OrderResponses.Create do
  @moduledoc """
  Return from venue adapters when creating an order
  """

  @type t :: %Tai.Trading.OrderResponses.Create{
          id: String.t(),
          status: atom,
          original_size: Decimal.t(),
          avg_price: Decimal.t(),
          leaves_qty: Decimal.t(),
          cumulative_qty: Decimal.t(),
          timestamp: DateTime.t() | nil
        }

  @enforce_keys [
    :id,
    :status,
    :avg_price,
    :original_size,
    :leaves_qty,
    :cumulative_qty
  ]
  defstruct [
    :id,
    :status,
    :avg_price,
    :original_size,
    :leaves_qty,
    :cumulative_qty,
    :timestamp
  ]
end
