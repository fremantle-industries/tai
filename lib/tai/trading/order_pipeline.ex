defmodule Tai.Trading.OrderPipeline do
  alias Tai.Trading

  defdelegate enqueue(submission), to: Trading.OrderPipeline.Enqueue, as: :execute_step
  defdelegate cancel(order), to: Trading.OrderPipeline.Cancel, as: :execute_step
end
