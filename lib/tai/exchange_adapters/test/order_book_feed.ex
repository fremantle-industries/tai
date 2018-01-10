defmodule Tai.ExchangeAdapters.Test.OrderBookFeed do
  use Tai.Exchanges.OrderBookFeed

  defp url, do: "ws://demos.kaazing.com/echo"

  def subscribe_to_order_books(_name, _symbols) do
    :ok
  end
end
