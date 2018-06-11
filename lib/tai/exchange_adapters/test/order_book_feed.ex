defmodule Tai.ExchangeAdapters.Test.OrderBookFeed do
  @moduledoc """
  Test adapter for an order book feed. Simulate a stream of order book updates
  """

  use Tai.Exchanges.OrderBookFeed

  def default_url, do: "ws://localhost:#{EchoBoy.Config.port()}/ws"

  def subscribe_to_order_books(_pid, _feed_id, _symbols), do: :ok

  def handle_msg(_msg, _state), do: nil
end
