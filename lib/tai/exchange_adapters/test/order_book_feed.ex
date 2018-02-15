defmodule Tai.ExchangeAdapters.Test.OrderBookFeed do
  use Tai.Exchanges.OrderBookFeed

  def url, do: "ws://demos.kaazing.com/echo"

  def subscribe_to_order_books(_pid, _symbols), do: :ok

  def handle_msg(_msg, _feed_id), do: nil
end
