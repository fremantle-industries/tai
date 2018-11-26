defmodule Tai.Trading.OrderPipeline do
  @type order :: Tai.Trading.Order.t()
  @type buy_limit :: Tai.Trading.Orders.BuyLimit.t()
  @type sell_limit :: Tai.Trading.Orders.SellLimit.t()

  @spec enqueue(buy_limit | sell_limit) :: order
  def enqueue(%Tai.Trading.Orders.BuyLimit{} = order) do
    order.venue_id
    |> Tai.Trading.OrderSubmission.buy_limit(
      order.account_id,
      order.product_symbol,
      order.price,
      order.qty,
      order.time_in_force,
      order.order_updated_callback
    )
    |> Tai.Trading.OrderPipeline.Enqueue.execute_step()
  end

  def enqueue(%Tai.Trading.Orders.SellLimit{} = order) do
    order.venue_id
    |> Tai.Trading.OrderSubmission.sell_limit(
      order.account_id,
      order.product_symbol,
      order.price,
      order.qty,
      order.time_in_force,
      order.order_updated_callback
    )
    |> Tai.Trading.OrderPipeline.Enqueue.execute_step()
  end

  @doc """
  Cancel a pending order
  """
  defdelegate cancel(order), to: Tai.Trading.OrderPipeline.Cancel, as: :execute_step
end
