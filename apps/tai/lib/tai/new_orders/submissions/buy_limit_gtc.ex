defmodule Tai.NewOrders.Submissions.BuyLimitGtc do
  alias __MODULE__

  @type product_type :: Tai.Venues.Product.type()
  @type t :: %BuyLimitGtc{
          venue: String.t(),
          credential: String.t(),
          venue_product_symbol: String.t(),
          product_symbol: String.t(),
          product_type: product_type,
          price: Decimal.t(),
          qty: Decimal.t(),
          close: boolean | nil,
          post_only: boolean,
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
    post_only
  ]a
  defstruct ~w[
    venue
    credential
    venue_product_symbol
    product_symbol
    product_type
    price
    qty
    post_only
    close
    order_updated_callback
  ]a
end
