defmodule Tai.Venues.Product do
  @type status ::
          :pre_trading
          | :trading
          | :post_trading
          | :end_of_day
          | :halt
          | :auction_match
          | :break
          | :settled
          | :unlisted

  @type symbol :: atom
  @type t :: %Tai.Venues.Product{
          exchange_id: atom,
          symbol: symbol,
          exchange_symbol: String.t(),
          status: status,
          margin: boolean,
          min_size: Decimal.t(),
          size_increment: Decimal.t(),
          min_notional: Decimal.t() | nil,
          min_price: Decimal.t() | nil,
          price_increment: Decimal.t() | nil,
          max_price: Decimal.t() | nil,
          max_size: Decimal.t() | nil,
          maker_fee: Decimal.t() | nil,
          taker_fee: Decimal.t() | nil
        }

  @enforce_keys [
    :exchange_id,
    :symbol,
    :exchange_symbol,
    :status,
    :margin,
    :min_size,
    :size_increment
  ]
  defstruct [
    :exchange_id,
    :symbol,
    :exchange_symbol,
    :status,
    :margin,
    :min_notional,
    :min_price,
    :min_size,
    :max_size,
    :max_price,
    :price_increment,
    :size_increment,
    :maker_fee,
    :taker_fee
  ]
end
