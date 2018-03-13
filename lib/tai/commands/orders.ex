defmodule Tai.Commands.Orders do
  alias Tai.{Exchanges.Account, Trading.OrderResponses}

  def buy_limit(exchange, symbol, price, size) do
    exchange
    |> Account.buy_limit(symbol, price, size)
    |> case do
      {:ok, order_response} ->
        IO.puts "create order success - id: #{order_response.id}, status: #{order_response.status}"
      {:error, %OrderResponses.InsufficientFunds{}} ->
        IO.puts "create order failure - insufficient funds"
    end
  end

  def sell_limit(exchange, symbol, price, size) do
    exchange
    |> Account.sell_limit(symbol, price, size)
    |> case do
      {:ok, order_response} ->
        IO.puts "create order success - id: #{order_response.id}, status: #{order_response.status}"
      {:error, %OrderResponses.InsufficientFunds{}} ->
        IO.puts "create order failure - insufficient funds"
    end
  end

  def order_status(exchange, order_id) do
    exchange
    |> Account.order_status(order_id)
    |> case do
      {:ok, status} ->
        IO.puts "status: #{status}"
      {:error, message} ->
        IO.puts "error: #{message}"
    end
  end

  def cancel_order(exchange, order_id) do
    exchange
    |> Account.cancel_order(order_id)
    |> case do
      {:ok, _canceled_order_id} ->
        IO.puts "cancel order success"
      {:error, message} ->
        IO.puts "error: #{message}"
    end
  end
end
