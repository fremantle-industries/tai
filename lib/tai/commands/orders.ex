defmodule Tai.Commands.Orders do
  alias Tai.Exchange

  def buy_limit(exchange, symbol, price, size) do
    exchange
    |> Exchange.buy_limit(symbol, price, size)
    |> case do
      {:ok, order_response} ->
        IO.puts "create order success - id: #{order_response.id}, status: #{order_response.status}"
      {:error, message} ->
        IO.puts "create order failure - #{message}"
    end
  end

  def sell_limit(exchange, symbol, price, size) do
    exchange
    |> Exchange.sell_limit(symbol, price, size)
    |> case do
      {:ok, order_response} ->
        IO.puts "create order success - id: #{order_response.id}, status: #{order_response.status}"
      {:error, message} ->
        IO.puts "create order failure - #{message}"
    end
  end

  def order_status(exchange, order_id) do
    exchange
    |> Exchange.order_status(order_id)
    |> case do
      {:ok, status} ->
        IO.puts "status: #{status}"
      {:error, message} ->
        IO.puts "error: #{message}"
    end
  end

  def cancel_order(exchange, order_id) do
    exchange
    |> Exchange.cancel_order(order_id)
    |> case do
      {:ok, _canceled_order_id} ->
        IO.puts "cancel order success"
      {:error, message} ->
        IO.puts "error: #{message}"
    end
  end
end
