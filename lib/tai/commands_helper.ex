defmodule Tai.CommandsHelper do
  alias Tai.{Exchange, Fund, Markets, Strategy}

  def help do
    IO.puts """
    * status
    * quotes exchange(:gdax), symbol(:btcusd)
    * buy_limit exchange(:gdax), symbol(:btcusd), price(101.12), size(1.2)
    * sell_limit exchange(:gdax), symbol(:btcusd), price(101.12), size(1.2)
    * order_status exchange(:gdax), order_id("f1bb2fa3-6218-45be-8691-21b98157f25a")
    * cancel_order exchange(:gdax), order_id("f1bb2fa3-6218-45be-8691-21b98157f25a")
    """
  end

  def status do
    IO.puts "#{Fund.balance} USD"
  end

  def quotes(feed_id, symbol) do
    [feed_id: feed_id, symbol: symbol]
    |> Markets.OrderBook.to_name
    |> Markets.OrderBook.quotes
    |> print_quotes
  end
  defp print_quotes({
    :ok,
    %{
      bids: [[price: bid_price, size: bid_size] | _remaining_bids],
      asks: [[price: ask_price, size: ask_size] | _remaining_asks]}
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

  def strategy(name) do
    name
    |> Strategy.info
    |> case do
      {:ok, info} ->
        IO.puts "started: #{info.started_at}"
    end
  end
end
