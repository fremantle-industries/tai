defmodule Tai.Events.Funding do
  @type t :: %Tai.Events.Funding{
          venue_id: atom,
          symbol: atom,
          timestamp: DateTime.t() | String.t(),
          received_at: DateTime.t(),
          interval: DateTime.t() | String.t(),
          rate: Decimal.t() | number,
          rate_daily: Decimal.t() | number
        }

  @enforce_keys [
    :venue_id,
    :symbol,
    :timestamp,
    :received_at,
    :interval,
    :rate,
    :rate_daily
  ]
  defstruct [
    :venue_id,
    :symbol,
    :timestamp,
    :received_at,
    :interval,
    :rate,
    :rate_daily
  ]
end
