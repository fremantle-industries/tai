defmodule Tai.Trading.OrderPipeline do
  @doc """
  Enqueue a buy limit order
  """
  def buy_limit(
        exchange_id,
        account_id,
        symbol,
        price,
        size,
        time_in_force,
        order_updated_callback \\ nil
      ) do
    exchange_id
    |> Tai.Trading.OrderSubmission.buy_limit(
      account_id,
      symbol,
      price,
      size,
      time_in_force,
      order_updated_callback
    )
    |> Tai.Trading.OrderPipeline.Enqueue.call()
  end

  @doc """
  Enqueue a sell limit order
  """
  def sell_limit(
        exchange_id,
        account_id,
        symbol,
        price,
        size,
        time_in_force,
        order_updated_callback \\ nil
      ) do
    exchange_id
    |> Tai.Trading.OrderSubmission.sell_limit(
      account_id,
      symbol,
      price,
      size,
      time_in_force,
      order_updated_callback
    )
    |> Tai.Trading.OrderPipeline.Enqueue.call()
  end

  @doc """
  Cancel a pending order
  """
  defdelegate cancel(order), to: Tai.Trading.OrderPipeline.Cancel, as: :call
end
