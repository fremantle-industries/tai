defmodule Tai.NewOrders.Submissions.BuyLimitIoc do
  alias __MODULE__

  @type product_type :: Tai.Venues.Product.type()
  @type t :: %BuyLimitIoc{
          venue: String.t(),
          credential: String.t(),
          venue_product_symbol: String.t(),
          product_symbol: String.t(),
          product_type: product_type,
          price: Decimal.t(),
          qty: Decimal.t(),
          close: boolean | nil,
          order_updated_callback: function | nil
        }

  @enforce_keys ~w[
    venue
    credential
    venue_product_symbol
    product_symbol
    product_type
    price
    qty
  ]a
  defstruct ~w[
    venue
    credential
    venue_product_symbol
    product_symbol
    product_type
    price
    qty
    close
    order_updated_callback
  ]a
end
