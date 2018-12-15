defmodule Tai.Trading.Orders do
  alias Tai.Trading.Orders

  @type order :: Tai.Trading.Order.t()
  @type submission :: Tai.Trading.OrderStore.submission()

  @spec create(submission) :: {:ok, order}
  defdelegate create(submission), to: Orders.Create
  defdelegate cancel(order), to: Orders.Cancel

  @spec broadcast(order) :: :ok
  def broadcast(%Tai.Trading.Order{} = order) do
    %Tai.Events.OrderUpdated{
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
    }
    |> Tai.Events.broadcast()
  end

  def execute_update_callback(_, %Tai.Trading.Order{order_updated_callback: nil}), do: :ok

  def execute_update_callback(previous, %Tai.Trading.Order{} = updated) do
    updated.order_updated_callback.(previous, updated)
  end
end
