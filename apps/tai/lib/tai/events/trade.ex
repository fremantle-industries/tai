defmodule Tai.Events.Trade do
  @type t :: %Tai.Events.Trade{
          venue_id: atom,
          symbol: atom,
          received_at: DateTime.t(),
          timestamp: DateTime.t() | String.t(),
          price: Decimal.t() | number,
          qty: Decimal.t() | number,
          side: atom
        }

  @enforce_keys [
    :venue_id,
    :symbol,
    :received_at,
    :timestamp,
    :price,
    :qty,
    :side
  ]
  defstruct [
    :venue_id,
    :symbol,
    :received_at,
    :timestamp,
    :price,
    :qty,
    :side
  ]
end
