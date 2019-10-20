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

  @typedoc """
  The product to buy/sell or the underlying product used to buy/sell. For the product BTCUSD

  - BTC = base asset
  - USD = quote asset
  """
  @type asset :: String.t()

  @typedoc """
  The underlying value of the product. Spot products will always have a value = 1. Derivative products
  can have values > 1.

  e.g. OkEx quarterly futures product has a value of 100 where 1 contract represents $100 USD.
  """
  @type value :: Decimal.t()

  @typedoc """
  A derivative contract where PnL settlement is a different asset to the base or quote assets.
  """
  @type quanto :: true | false

  @typedoc """
  A derivative contract where the PnL settlement is in the base asset, e.g. XBTUSD settles PnL in XBT
  """
  @type inverse :: true | false

  @type symbol :: atom
  @type venue_symbol :: String.t()
  @type type :: :spot | :future | :swap | :option
  @type t :: %Tai.Venues.Product{
          venue_id: Tai.Venues.Adapter.venue_id(),
          symbol: symbol,
          venue_symbol: venue_symbol,
          alias: String.t() | nil,
          base: asset,
          quote: asset,
          status: status,
          type: type,
          price_increment: Decimal.t(),
          size_increment: Decimal.t(),
          min_price: Decimal.t(),
          min_size: Decimal.t(),
          min_notional: Decimal.t() | nil,
          max_price: Decimal.t() | nil,
          max_size: Decimal.t() | nil,
          value: value,
          is_quanto: quanto,
          is_inverse: inverse,
          maker_fee: Decimal.t() | nil,
          taker_fee: Decimal.t() | nil
        }

  @enforce_keys ~w(
    venue_id
    symbol
    venue_symbol
    base
    quote
    status
    type
    price_increment
    size_increment
    min_price
    min_size
    value
    is_quanto
    is_inverse
  )a
  defstruct ~w(
    venue_id
    symbol
    venue_symbol
    alias
    base
    quote
    status
    type
    price_increment
    size_increment
    min_notional
    min_price
    min_size
    max_size
    max_price
    value
    is_quanto
    is_inverse
    maker_fee
    taker_fee
  )a
end
