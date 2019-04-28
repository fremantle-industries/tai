defmodule Tai.Trading.OrderSubmissions.BuyLimitGtc do
  @type product_type :: Tai.Venues.Product.type()
  @type t :: %Tai.Trading.OrderSubmissions.BuyLimitGtc{
          venue_id: atom,
          account_id: atom,
          product_symbol: atom,
          product_type: product_type,
          price: Decimal.t(),
          qty: Decimal.t(),
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
    order_updated_callback
  )a
end
