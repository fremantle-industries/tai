defmodule Tai.Trading.OrderPipeline.Enqueue do
  require Logger

  def call(submission) do
    [order] = Tai.Trading.OrderStore.add(submission)
    log_enqueued(order)
    Tai.Trading.Order.updated_callback(nil, order)
    Tai.Trading.OrderPipeline.Send.call(order)

    order
  end

  defp log_enqueued(order) do
    Logger.info(fn -> "order enqueued - client_id: #{order.client_id}" end)
  end
end
