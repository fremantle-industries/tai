defmodule Tai.ExchangeAdapters.Test.OrderBookFeed do
  use Tai.Exchanges.OrderBookFeed

  def default_url, do: "ws://localhost:#{EchoBoy.Config.port}/ws"

  def subscribe_to_order_books(_pid, _symbols), do: :ok

  def handle_msg(_msg, _feed_id), do: nil
end
