defmodule Tai.Events.PositionUpdate do
  @type t :: %Tai.Events.PositionUpdate{
          venue_id: atom,
          symbol: atom,
          received_at: DateTime.t(),
          timestamp: DateTime.t() | String.t(),
          mark_price: Decimal.t() | number,
          liquidation_price: Decimal.t() | number | nil,
          last_price: Decimal.t() | number,
          current_timestamp: DateTime.t() | String.t(),
          current_qty: number,
          currency: String.t(),
          account: number
        }

  @enforce_keys [
    :venue_id,
    :symbol,
    :received_at,
    :timestamp,
    :mark_price,
    :liquidation_price,
    :last_price,
    :current_timestamp,
    :current_qty,
    :currency,
    :account
  ]
  defstruct [
    :venue_id,
    :symbol,
    :received_at,
    :timestamp,
    :mark_price,
    :liquidation_price,
    :last_price,
    :current_timestamp,
    :current_qty,
    :currency,
    :account
  ]
end
