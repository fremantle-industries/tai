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
      venue_order_id: order.venue_order_id,
      product_symbol: order.symbol,
      side: order.side,
      type: order.type,
      time_in_force: order.time_in_force,
      status: order.status,
      price: order.price,
      size: order.size,
      error_reason: order.error_reason,
      cumulative_qty: order.cumulative_qty
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
