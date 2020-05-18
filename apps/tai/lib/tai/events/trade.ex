defmodule Tai.Events.Trade do
  @type t :: %Tai.Events.Trade{
          venue_id: atom,
          symbol: atom,
          received_at: DateTime.t(),
          timestamp: DateTime.t(),
          price: Decimal.t() | number,
          qty: Decimal.t() | number,
          side: :buy | :sell,
          venue_trade_id: String.t()
        }

  @enforce_keys ~w(
    venue_id
    symbol
    received_at
    timestamp
    price
    qty
    side
  )a
  defstruct ~w(
    venue_id
    symbol
    received_at
    timestamp
    price
    qty
    side
    venue_trade_id
  )a
end
