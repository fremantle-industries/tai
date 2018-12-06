defmodule Tai.Trading.OrderSubmissions.BuyLimitGtc do
  @type t :: %Tai.Trading.OrderSubmissions.BuyLimitGtc{
          venue_id: atom,
          account_id: atom,
          product_symbol: atom,
          price: Decimal.t(),
          qty: Decimal.t(),
          post_only: boolean,
          order_updated_callback: function | nil
        }

  @enforce_keys [
    :venue_id,
    :account_id,
    :product_symbol,
    :price,
    :qty,
    :post_only
  ]
  defstruct [
    :venue_id,
    :account_id,
    :product_symbol,
    :price,
    :qty,
    :post_only,
    :order_updated_callback
  ]
end
