defmodule Tai.Events.UpdateLiquidationPrice do
  @type t :: %Tai.Events.UpdateLiquidationPrice{
          venue_id: atom,
          symbol: atom,
          received_at: DateTime.t(),
          price: Decimal.t() | number,
          order_id: String.t()
        }

  @enforce_keys [
    :venue_id,
    :symbol,
    :received_at,
    :price,
    :order_id
  ]
  defstruct [
    :venue_id,
    :symbol,
    :received_at,
    :price,
    :order_id
  ]
end
