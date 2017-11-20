defmodule TaiHelper do
  def status do
    IO.puts "#{Tai.Fund.balance} USD"
  end

  def quotes(exchange, symbol) do
    case Tai.Exchange.quotes(exchange, symbol) do
      {bid, ask} ->
        IO.puts """
        #{ask.price}/#{ask.volume} [#{ask.age}s]
        ---
        #{bid.price}/#{bid.volume} [#{bid.age}s]
        """
    end
  end
end
