defmodule Tai.IEx.Commands.NewOrders do
  @moduledoc """
  Display the list of orders and their details
  """

  import Tai.IEx.Commands.Table, only: [render!: 2]

  @header [
    "Venue",
    "Credential",
    "Product Symbol",
    "Product Type",
    "Side",
    "Type",
    "Price",
    "Qty",
    "Leaves Qty",
    "Cumulative Qty",
    "Time in Force",
    "Status",
    "Client ID",
    "Venue Order ID",
    "Updated At"
  ]

  @spec new_orders :: no_return
  def new_orders do
    Tai.Commander.new_orders()
    |> Enum.map(fn order ->
      [
        order.venue,
        order.credential,
        order.product_symbol,
        order.product_type,
        order.side,
        order.type,
        order.price,
        order.qty,
        order.leaves_qty,
        order.cumulative_qty,
        order.time_in_force,
        order.status,
        order.client_id |> Tai.Utils.String.truncate(6),
        order.venue_order_id && order.venue_order_id |> Tai.Utils.String.truncate(6),
        order.updated_at
      ]
    end)
    |> render!(@header)
  end
end
