defmodule Tai.Events.UpdateLiquidationLeavesQty do
  @type t :: %Tai.Events.UpdateLiquidationLeavesQty{
          venue_id: atom,
          symbol: atom,
          received_at: DateTime.t(),
          leaves_qty: Decimal.t() | number,
          order_id: String.t()
        }

  @enforce_keys [
    :venue_id,
    :symbol,
    :received_at,
    :leaves_qty,
    :order_id
  ]
  defstruct [
    :venue_id,
    :symbol,
    :received_at,
    :leaves_qty,
    :order_id
  ]
end
