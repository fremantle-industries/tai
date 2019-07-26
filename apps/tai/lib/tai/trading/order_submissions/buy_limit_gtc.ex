defmodule Tai.Trading.OrderSubmissions.BuyLimitGtc do
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type account_id :: Tai.Venues.Adapter.account_id()
  @type product_symbol :: Tai.Venues.Product.symbol()
  @type product_type :: Tai.Venues.Product.type()
  @type t :: %Tai.Trading.OrderSubmissions.BuyLimitGtc{
          venue_id: venue_id,
          account_id: account_id,
          product_symbol: product_symbol,
          product_type: product_type,
          price: Decimal.t(),
          qty: Decimal.t(),
          close: boolean | nil,
          post_only: boolean,
          order_updated_callback: function | nil
        }

  @enforce_keys ~w(
    venue_id
    account_id
    product_symbol
    product_type
    price
    qty
    post_only
  )a
  defstruct ~w(
    venue_id
    account_id
    product_symbol
    product_type
    price
    qty
    post_only
    close
    order_updated_callback
  )a
end
