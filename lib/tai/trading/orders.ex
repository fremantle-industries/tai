defmodule Tai.Trading.Orders do
  alias Tai.Trading.Orders

  @type order :: Tai.Trading.Order.t()

  defdelegate create(submission), to: Orders.Create
  defdelegate amend(order, attrs), to: Orders.Amend
  defdelegate cancel(order), to: Orders.Cancel

  @spec broadcast(order) :: :ok
  def broadcast(%Tai.Trading.Order{} = order) do
    %Tai.Events.OrderUpdated{
      client_id: order.client_id,
      venue_id: order.exchange_id,
      account_id: order.account_id,
      enqueued_at: order.enqueued_at,
      updated_at: order.updated_at,
      venue_order_id: order.venue_order_id,
      venue_created_at: order.venue_created_at,
      venue_updated_at: order.venue_updated_at,
      product_symbol: order.symbol,
      side: order.side,
      type: order.type,
      time_in_force: order.time_in_force,
      status: order.status,
      price: order.price,
      avg_price: order.avg_price,
      qty: order.qty,
      leaves_qty: order.leaves_qty,
      cumulative_qty: order.cumulative_qty,
      error_reason: order.error_reason
    }
    |> Tai.Events.broadcast()
  end

  @spec updated!(order | nil, order) :: :ok
  def updated!(previous, %Tai.Trading.Order{} = updated) do
    broadcast(updated)

    if updated.order_updated_callback do
      updated.order_updated_callback.(previous, updated)
    else
      :ok
    end
  end
end
