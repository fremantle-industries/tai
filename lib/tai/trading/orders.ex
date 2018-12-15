defmodule Tai.Trading.Orders do
  alias Tai.Trading.Orders

  defdelegate enqueue(submission), to: Orders.Enqueue, as: :execute_step
  defdelegate cancel(order), to: Orders.Cancel, as: :execute_step
end
