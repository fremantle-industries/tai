defmodule Tai.Events.InsertLiquidation do
  @type t :: %Tai.Events.InsertLiquidation{
          venue_id: atom,
          symbol: atom,
          received_at: DateTime.t(),
          price: Decimal.t() | number,
          leaves_qty: Decimal.t() | number,
          side: atom,
          order_id: String.t()
        }

  @enforce_keys [
    :venue_id,
    :symbol,
    :received_at,
    :price,
    :leaves_qty,
    :side,
    :order_id
  ]
  defstruct [
    :venue_id,
    :symbol,
    :received_at,
    :price,
    :leaves_qty,
    :side,
    :order_id
  ]
end
