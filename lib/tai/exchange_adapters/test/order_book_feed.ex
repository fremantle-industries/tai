defmodule Tai.ExchangeAdapters.Test.OrderBookFeed do
  @moduledoc """
  Test adapter for an order book feed. Simulate a stream of order book updates
  """

  use Tai.Exchanges.OrderBookFeed

  def default_url, do: "ws://localhost:#{EchoBoy.Config.port()}/ws"

  def subscribe_to_order_books(_pid, :subscribe_error, symbols) do
    {:error, "could not subscribe to #{symbols.join(",")}"}
  end

  def subscribe_to_order_books(_pid, _feed_id, _symbols), do: :ok

  def handle_msg(_msg, state), do: {:ok, state}
end
