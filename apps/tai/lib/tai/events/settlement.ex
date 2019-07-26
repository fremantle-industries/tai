defmodule Tai.Events.Settlement do
  @type t :: %Tai.Events.Settlement{
          venue_id: atom,
          symbol: atom,
          timestamp: DateTime.t() | String.t(),
          received_at: DateTime.t(),
          price: Decimal.t() | number
        }

  @enforce_keys [
    :venue_id,
    :symbol,
    :timestamp,
    :received_at,
    :price
  ]
  defstruct [
    :venue_id,
    :symbol,
    :timestamp,
    :received_at,
    :price
  ]
end
