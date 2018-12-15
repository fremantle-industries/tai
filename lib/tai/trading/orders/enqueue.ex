defmodule Tai.Trading.Orders.Enqueue do
  alias Tai.Trading

  @type submission :: Trading.OrderStore.submission()
  @type order :: Trading.Order.t()

  @spec execute_step(submission) :: order
  def execute_step(submission) do
    {:ok, order} = Trading.OrderStore.add(submission)

    Task.start_link(fn ->
      order
      |> log_enqueued()
      |> initial_update_callback()
      |> next_step
    end)

    order
  end

  defp log_enqueued(order) do
    Trading.Orders.Events.info(order)
    order
  end

  defp initial_update_callback(order) do
    Trading.Order.execute_update_callback(nil, order)
    order
  end

  defp next_step(order) do
    Trading.Orders.Send.execute_step(order)
  end
end
