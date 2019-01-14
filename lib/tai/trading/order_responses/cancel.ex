defmodule Tai.Trading.OrderResponses.Cancel do
  @moduledoc """
  Return from venue adapters when canceling an order
  """

  @type t :: %Tai.Trading.OrderResponses.Cancel{
          id: String.t(),
          status: atom,
          leaves_qty: Decimal.t(),
          venue_updated_at: DateTime.t()
        }

  @enforce_keys [
    :id,
    :status,
    :leaves_qty,
    :venue_updated_at
  ]
  defstruct [
    :id,
    :status,
    :leaves_qty,
    :venue_updated_at
  ]
end
