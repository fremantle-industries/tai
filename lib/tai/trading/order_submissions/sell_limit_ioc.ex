defmodule Tai.Trading.OrderSubmissions.SellLimitIoc do
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type account_id :: Tai.Venues.Adapter.account_id()
  @type product_symbol :: Tai.Venues.Product.symbol()
  @type product_type :: Tai.Venues.Product.type()
  @type t :: %Tai.Trading.OrderSubmissions.SellLimitIoc{
          venue_id: venue_id,
          account_id: account_id,
          product_symbol: product_symbol,
          product_type: product_type,
          price: Decimal.t(),
          qty: Decimal.t(),
          order_updated_callback: function | nil
        }

  @enforce_keys ~w(
    venue_id
    account_id
    product_symbol
    product_type
    price
    qty
  )a
  defstruct ~w(
    venue_id
    account_id
    product_symbol
    product_type
    price
    qty
    order_updated_callback
  )a
end
