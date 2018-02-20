defmodule Tai.Exchanges.OrderBookFeedTest do
  use ExUnit.Case
  doctest Tai.Exchanges.OrderBookFeed

  alias Tai.Exchanges.OrderBookFeed

  defmodule ExampleOrderBookFeed do
    use OrderBookFeed

    def default_url, do: "ws://localhost:#{EchoBoy.Config.port}/ws/"
    def subscribe_to_order_books(_pid, _symbols), do: :ok
    def handle_msg(msg, feed_id), do: send :test, {msg, feed_id}
  end

  test "start_link returns an :ok, pid tuple when successful" do
    assert {:ok, _pid} = ExampleOrderBookFeed.start_link(
      feed_id: :example_feed,
      symbols: [:btcusd, :ltcusd]
    )
  end

  test "start_link returns an :error, reason tuple when the url is not valid" do
    defmodule InvalidUrlOrderBookFeed do
      use Tai.Exchanges.OrderBookFeed

      def default_url, do: ""
      def subscribe_to_order_books(_pid, _symbols), do: :ok
      def handle_msg(_msg, _feed_id), do: nil
    end

    assert InvalidUrlOrderBookFeed.start_link(
      feed_id: :example_feed,
      symbols: [:btcusd, :ltcusd]
    ) == {:error, %WebSockex.URLError{url: ""}}
  end

  test "calls the handle_msg callback when it receives a WebSocket message" do
    Process.register self(), :test

    {:ok, pid} = ExampleOrderBookFeed.start_link(
      feed_id: :example_feed,
      symbols: [:btcusd, :ltcusd]
    )

    WebSockex.send_frame(pid, {:text, %{hello: "world!"} |> JSON.encode!})

    assert_receive {%{"hello" => "world!"}, :example_feed}
  end

  @tag :skip
  test "logs an error message when disconnected"
end
