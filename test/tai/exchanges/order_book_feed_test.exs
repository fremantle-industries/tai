defmodule Tai.Exchanges.OrderBookFeedTest do
  use ExUnit.Case, async: true
  doctest Tai.Exchanges.OrderBookFeed

  import ExUnit.CaptureLog

  alias Tai.Exchanges.OrderBookFeed

  defmodule ExampleOrderBookFeed do
    use OrderBookFeed

    def default_url, do: "ws://localhost:#{EchoBoy.Config.port}/ws/"
    def subscribe_to_order_books(_pid, _feed_id, _symbols), do: :ok
    def handle_msg(msg, feed_id), do: send :test, {msg, feed_id}

    def handle_disconnect(conn_status, feed_id) do
      val = super(conn_status, feed_id)
      send :test, :disconnected

      val
    end
  end

  setup do
    Process.register self(), :test

    :ok
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
      def subscribe_to_order_books(_pid, _feed_id, _symbols), do: :ok
      def handle_msg(_msg, _feed_id), do: nil
    end

    assert InvalidUrlOrderBookFeed.start_link(
      feed_id: :example_feed,
      symbols: [:btcusd, :ltcusd]
    ) == {:error, %WebSockex.URLError{url: ""}}
  end

  test "calls the handle_msg callback when it receives a WebSocket message" do
    {:ok, pid} = ExampleOrderBookFeed.start_link(
      feed_id: :example_feed,
      symbols: [:btcusd, :ltcusd]
    )

    WebSockex.send_frame(pid, {:text, %{hello: "world!"} |> JSON.encode!})

    assert_receive {%{"hello" => "world!"}, :example_feed}
  end

  test "raises an error when the message is not valid JSON" do
    Process.flag :trap_exit, true

    {:ok, pid} = ExampleOrderBookFeed.start_link(
      feed_id: :example_feed,
      symbols: [:btcusd, :ltcusd]
    )

    WebSockex.send_frame(pid, {:text, "not-json"})

    assert_receive({:EXIT, ^pid, {%JSON.Decoder.UnexpectedTokenError{token: "not-json"}, _}})
  end

  test "logs a debug message for each frame received with a :text msg" do
    {:ok, pid} = ExampleOrderBookFeed.start_link(
      feed_id: :example_feed,
      symbols: [:btcusd, :ltcusd]
    )

    assert capture_log(fn ->
      WebSockex.send_frame(pid, {:text, %{type: "test_message"} |> JSON.encode!})

      assert_receive {%{"type" => "test_message"}, :example_feed}
    end) =~ "[debug] [order_book_feed_example_feed] received msg: {\"type\":\"test_message\"}"
  end

  test "logs an error message when disconnected" do
    {:ok, pid} = ExampleOrderBookFeed.start_link(
      feed_id: :example_feed,
      symbols: [:btcusd, :ltcusd]
    )

    assert capture_log(fn ->
      WebSockex.send_frame(pid, {:text, "close"})

      assert_receive :disconnected
    end) =~ "[error] [order_book_feed_example_feed] disconnected - reason: {:remote, 1000, \"\"}"
  end
end
