defmodule Tai.Events.DeleteLiquidation do
  @type t :: %Tai.Events.DeleteLiquidation{
          venue_id: atom,
          symbol: atom,
          received_at: DateTime.t(),
          order_id: String.t()
        }

  @enforce_keys [
    :venue_id,
    :symbol,
    :received_at,
    :order_id
  ]
  defstruct [
    :venue_id,
    :symbol,
    :received_at,
    :order_id
  ]
end
