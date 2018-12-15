defmodule Tai.Trading.Orders.Events do
  def info(%Tai.Trading.Order{} = order) do
    Tai.Events.broadcast(%Tai.Events.OrderUpdated{
      client_id: order.client_id,
      venue_id: order.exchange_id,
      account_id: order.account_id,
      product_symbol: order.symbol,
      side: order.side,
      type: order.type,
      time_in_force: order.time_in_force,
      status: order.status,
      price: order.price,
      size: order.size,
      error_reason: order.error_reason,
      executed_size: order.executed_size
    })
  end
end
