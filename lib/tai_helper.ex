defmodule TaiHelper do
  def status do
    IO.puts "#{Tai.Fund.balance} USD"
  end

  def quotes(exchange, symbol) do
    case Tai.Exchange.quotes(exchange, symbol) do
      {bid, ask} ->
        IO.puts """
        #{ask.price}/#{ask.size} [#{ask.age}s]
        ---
        #{bid.price}/#{bid.size} [#{bid.age}s]
        """
    end
  end

  def buy_limit(exchange, symbol, price, size) do
    Tai.Exchange.buy_limit(
      exchange,
      symbol,
      price,
      size
    )
    |> case do
      {:ok, order_response} ->
        IO.puts "create order success - id: #{order_response.id}, status: #{order_response.status}"
      {:error, message} ->
        IO.puts "create order failure - #{message}"
    end
  end
end
