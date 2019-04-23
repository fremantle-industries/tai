defmodule Tai.Trading.OrderResponses.Cancel do
  @moduledoc """
  Return from venue adapters when canceling an order
  """

  @type t :: %Tai.Trading.OrderResponses.Cancel{
          id: String.t(),
          status: atom,
          leaves_qty: Decimal.t(),
          venue_timestamp: DateTime.t()
        }

  @enforce_keys ~w(
    id
    status
    leaves_qty
    venue_timestamp
  )a
  defstruct ~w(
    id
    status
    leaves_qty
    venue_timestamp
  )a
end
