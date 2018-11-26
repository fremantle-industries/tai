defmodule Tai.Trading.Orders.SellLimit do
  @type t :: %Tai.Trading.Orders.SellLimit{
          venue_id: atom,
          account_id: atom,
          product_symbol: atom,
          price: number,
          qty: number,
          time_in_force: Tai.Trading.Order.time_in_force(),
          order_updated_callback: function | nil
        }

  @enforce_keys [
    :venue_id,
    :account_id,
    :product_symbol,
    :price,
    :qty,
    :time_in_force
  ]
  defstruct [
    :venue_id,
    :account_id,
    :product_symbol,
    :price,
    :qty,
    :time_in_force,
    :order_updated_callback
  ]
end
