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
    :min_notional,
    :min_price,
    :min_size,
    :max_size,
    :max_price,
    :price_increment,
    :size_increment
  ]
end
