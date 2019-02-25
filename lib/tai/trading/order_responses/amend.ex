defmodule Tai.Trading.OrderResponses.Amend do
  @moduledoc """
  Return from venue adapters when amending an order
  """

  @type t :: %Tai.Trading.OrderResponses.Amend{
          id: String.t(),
          status: atom,
          price: Decimal.t(),
          leaves_qty: Decimal.t(),
          cumulative_qty: Decimal.t(),
          received_at: DateTime.t(),
          venue_timestamp: DateTime.t()
        }

  @enforce_keys [
    :id,
    :status,
    :price,
    :leaves_qty,
    :cumulative_qty,
    :received_at,
    :venue_timestamp
  ]
  defstruct [
    :id,
    :status,
    :price,
    :leaves_qty,
    :cumulative_qty,
    :received_at,
    :venue_timestamp
  ]
end
