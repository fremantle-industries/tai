defmodule Tai.Trading.OrderPipeline.Enqueue do
  def execute_step(%Tai.Trading.OrderSubmission{} = submission) do
    [order] = Tai.Trading.OrderStore.add(submission)

    Task.start_link(fn ->
      order
      |> log_enqueued()
      |> initial_update_callback()
      |> next_step
    end)

    order
  end

  defp log_enqueued(order) do
    Tai.Trading.OrderPipeline.Logger.info(order)
    order
  end

  defp initial_update_callback(order) do
    Tai.Trading.Order.execute_update_callback(nil, order)
    order
  end

  defp next_step(order) do
    Tai.Trading.OrderPipeline.Send.execute_step(order)
  end
end
