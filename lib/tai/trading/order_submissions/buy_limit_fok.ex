defmodule Tai.Trading.OrderSubmissions.BuyLimitFok do
  @type product_type :: Tai.Venues.Product.type()
  @type t :: %Tai.Trading.OrderSubmissions.BuyLimitFok{
          venue_id: atom,
          account_id: atom,
          product_symbol: atom,
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
