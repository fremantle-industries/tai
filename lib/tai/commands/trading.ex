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

  def order_status(exchange_id, account_id, order_id) do
    exchange_id
    |> Tai.Exchanges.Account.order_status(account_id, order_id)
    |> case do
      {:ok, status} ->
        IO.puts("status: #{status}")

      {:error, message} ->
        IO.puts("error: #{message}")
    end
  end

  def cancel_order(exchange_id, account_id, order_id) do
    exchange_id
    |> Tai.Exchanges.Account.cancel_order(account_id, order_id)
    |> case do
      {:ok, _canceled_order_id} ->
        IO.puts("cancel order success")

      {:error, message} ->
        IO.puts("error: #{message}")
    end
  end
end
