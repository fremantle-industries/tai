defmodule Tai.Commands.Orders do
  @moduledoc """
  Display the list of orders and their details
  """

  import Tai.Commands.Table, only: [render!: 2]

  @header [
    "Venue",
    "Account",
    "Symbol",
    "Side",
    "Type",
    "Price",
    "Avg Price",
    "Qty",
    "Leaves Qty",
    "Cumulative Qty",
    "Time in Force",
    "Status",
    "Client ID",
    "Venue Order ID",
    "Enqueued At",
    "Venue Created At",
    "Updated At",
    "Venue Updated At",
    "Error Reason"
  ]

  @spec orders :: no_return
  def orders do
    Tai.Trading.OrderStore.all()
    |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))
    |> Enum.map(fn order ->
      [
        order.exchange_id,
        order.account_id,
        order.symbol,
        order.side,
        order.type,
        order.price,
        order.avg_price,
        order.qty,
        order.leaves_qty,
        order.cumulative_qty,
        order.time_in_force,
        order.status,
        order.client_id |> trunc_id(),
        order.venue_order_id && order.venue_order_id |> trunc_id(),
        Timex.from_now(order.enqueued_at),
        order.venue_created_at && Timex.from_now(order.venue_created_at),
        order.updated_at && Timex.from_now(order.updated_at),
        order.venue_updated_at && Timex.from_now(order.venue_updated_at),
        order.error_reason && inspect(order.error_reason)
      ]
    end)
    |> render!(@header)
  end

  defp trunc_id(val), do: "#{val |> String.slice(0..5)}..."
end
