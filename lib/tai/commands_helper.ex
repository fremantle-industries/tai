defmodule Tai.CommandsHelper do
  def status do
    IO.puts "#{Tai.Fund.balance} USD"
  end

  def quotes(exchange, symbol) do
    exchange
    |> Tai.Exchange.quotes(symbol)
    |> case do
      {:ok, bid, ask} ->
        IO.puts """
        #{ask.price}/#{ask.size} [#{ask.age}s]
        ---
        #{bid.price}/#{bid.size} [#{bid.age}s]
        """
      {:error, message} ->
        IO.puts "error: #{message}"
    end
  end

  def buy_limit(exchange, symbol, price, size) do
    exchange
    |> Tai.Exchange.buy_limit(symbol, price, size)
    |> case do
      {:ok, order_response} ->
        IO.puts "create order success - id: #{order_response.id}, status: #{order_response.status}"
      {:error, message} ->
        IO.puts "create order failure - #{message}"
    end
  end

  def sell_limit(exchange, symbol, price, size) do
    exchange
    |> Tai.Exchange.sell_limit(symbol, price, size)
    |> case do
      {:ok, order_response} ->
        IO.puts "create order success - id: #{order_response.id}, status: #{order_response.status}"
      {:error, message} ->
        IO.puts "create order failure - #{message}"
    end
  end

  def order_status(exchange, order_id) do
    exchange
    |> Tai.Exchange.order_status(order_id)
    |> case do
      {:ok, status} ->
        IO.puts "status: #{status}"
      {:error, message} ->
        IO.puts "error: #{message}"
    end
  end

  def cancel_order(exchange, order_id) do
    exchange
    |> Tai.Exchange.cancel_order(order_id)
    |> case do
      {:ok, _canceled_order_id} ->
        IO.puts "cancel order success"
      {:error, message} ->
        IO.puts "error: #{message}"
    end
  end
end
