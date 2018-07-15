defmodule Tai.Exchanges.Product do
  @type t :: %Tai.Exchanges.Product{}

  @enforce_keys [
    :exchange_id,
    :symbol,
    :exchange_symbol,
    :status,
    :min_notional
  ]
  defstruct [
    :exchange_id,
    :symbol,
    :exchange_symbol,
    :status,
    :min_price,
    :max_price,
    :tick_size,
    :min_size,
    :max_size,
    :step_size,
    :min_notional
  ]
end
