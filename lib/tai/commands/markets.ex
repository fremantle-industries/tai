defmodule Tai.Commands.Markets do
  alias Tai.Markets.OrderBook

  def quotes(feed_id, symbol) do
    [feed_id: feed_id, symbol: symbol]
    |> OrderBook.to_name
    |> OrderBook.quotes
    |> print
  end

  defp print({
    :ok,
    %{
      bids: [[price: bid_price, size: bid_size] | _bids_tail],
      asks: [[price: ask_price, size: ask_size] | _asks_tail]}
    }
  ) do
    IO.puts """
    #{Decimal.new(ask_price)}/#{Decimal.new(ask_size)}
    ---
    #{Decimal.new(bid_price)}/#{Decimal.new(bid_size)}
    """
  end
  # TODO: Figure out how to trap calls to process with name that doesn't exist
  # defp print_quotes({:error, message}) do
  #   IO.puts "error: #{message}"
  # end
end
