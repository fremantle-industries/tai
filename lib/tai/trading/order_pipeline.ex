defmodule Tai.Trading.OrderPipeline do
  alias Tai.Trading

  @type order :: Trading.Order.t()
  @type submission :: Tai.Trading.OrderStore.submission()

  @spec enqueue(submission) :: order
  def enqueue(submission) do
    submission
    |> Trading.OrderPipeline.Enqueue.execute_step()
  end

  @doc """
  Cancel a pending order
  """
  defdelegate cancel(order), to: Trading.OrderPipeline.Cancel, as: :execute_step
end
