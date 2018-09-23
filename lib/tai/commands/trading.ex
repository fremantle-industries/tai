defmodule Tai.Commands.Trading do
  @moduledoc """
  Commands to submit and manage orders for an account
  """

  def buy_limit(exchange_id, account_id, symbol, price, size, time_in_force) do
    exchange_id
    |> Tai.Trading.OrderPipeline.buy_limit(account_id, symbol, price, size, time_in_force)
    |> render_order
  end

  def sell_limit(exchange_id, account_id, symbol, price, size, time_in_force) do
    exchange_id
    |> Tai.Trading.OrderPipeline.sell_limit(account_id, symbol, price, size, time_in_force)
    |> render_order
  end

  defp render_order(order) do
    IO.puts("order enqueued. client_id: #{order.client_id}")
  end
end
