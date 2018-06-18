defmodule Tai.Exchanges.OrderBookFeedTest do
  use ExUnit.Case, async: true
  doctest Tai.Exchanges.OrderBookFeed

  import ExUnit.CaptureLog

  alias Tai.{Exchanges.OrderBookFeed, WebSocket}

  defmodule ExampleOrderBookFeed do
    use OrderBookFeed

    def default_url, do: "ws://localhost:#{EchoBoy.Config.port()}/ws/"
    def subscribe_to_order_books(_pid, _feed_id, _symbols), do: :ok

    def handle_msg(msg, %OrderBookFeed{} = state) do
      counter = state.store |> Map.get(:counter, 0)
      new_store = state.store |> Map.put(:counter, counter + 1)
      new_state = state |> Map.put(:store, new_store)

      send(:test, {msg, state})

      case msg do
        %{"return" => "error"} -> {:error, msg}
        _ -> {:ok, new_state}
      end
    end

    def handle_disconnect(conn_status, state) do
      val = super(conn_status, state)
      send(:test, :disconnected)

      val
    end
  end

  setup do
    Process.register(self(), :test)

    :ok
  end

  test "start_link returns an :ok, pid tuple when successful" do
    assert {:ok, _pid} =
             ExampleOrderBookFeed.start_link(
               feed_id: :example_feed,
               symbols: [:btc_usd, :ltc_usd]
             )
  end

  test "start_link returns an :error, reason tuple when the url is not valid" do
    defmodule InvalidUrlOrderBookFeed do
      use Tai.Exchanges.OrderBookFeed

      def default_url, do: ""
      def subscribe_to_order_books(_pid, _feed_id, _symbols), do: :ok
      def handle_msg(_msg, _state), do: nil
    end

    assert InvalidUrlOrderBookFeed.start_link(
             feed_id: :example_feed,
             symbols: [:btc_usd, :ltc_usd]
           ) == {:error, %WebSockex.URLError{url: ""}}
  end

  test "logs a connection message" do
    log_msg =
      capture_log(fn ->
        ExampleOrderBookFeed.start_link(
          feed_id: :example_feed,
          symbols: [:btc_usd, :ltc_usd]
        )

        :timer.sleep(100)
      end)

    assert log_msg =~ "connected"
  end

  test "calls the handle_msg callback when it receives a WebSocket message" do
    {:ok, pid} =
      ExampleOrderBookFeed.start_link(
        feed_id: :example_feed,
        symbols: [:btc_usd, :ltc_usd]
      )

    WebSocket.send_json_msg(pid, %{hello: "world!"})

    assert_receive {
      %{"hello" => "world!"},
      %OrderBookFeed{feed_id: :example_feed}
    }
  end

  test "handle_msg updates the state when it returns an ok, state tuple" do
    {:ok, pid} =
      ExampleOrderBookFeed.start_link(
        feed_id: :example_feed,
        symbols: [:btc_usd, :ltc_usd]
      )

    WebSocket.send_json_msg(pid, %{hello: "world!"})

    assert_receive {
      %{"hello" => "world!"},
      %OrderBookFeed{feed_id: :example_feed}
    }

    WebSocket.send_json_msg(pid, %{hello: "world!"})

    assert_receive {
      %{"hello" => "world!"},
      %OrderBookFeed{feed_id: :example_feed, store: %{counter: 1}}
    }
  end

  test "raises an error when the message is not valid JSON" do
    Process.flag(:trap_exit, true)

    {:ok, pid} =
      ExampleOrderBookFeed.start_link(
        feed_id: :example_feed,
        symbols: [:btc_usd, :ltc_usd]
      )

    WebSocket.send_msg(pid, "not-json")

    assert_receive({:EXIT, ^pid, {%Poison.SyntaxError{}, _}})
  end

  test "logs a debug message for each frame received with a :text msg" do
    {:ok, pid} =
      ExampleOrderBookFeed.start_link(
        feed_id: :example_feed,
        symbols: [:btc_usd, :ltc_usd]
      )

    log_msg =
      capture_log(fn ->
        WebSocket.send_json_msg(pid, %{type: "test_message"})

        assert_receive {
          %{"type" => "test_message"},
          %OrderBookFeed{feed_id: :example_feed}
        }
      end)

    assert log_msg =~ "[debug] received msg: {\"type\":\"test_message\"}"
  end

  test "logs an error message when disconnected" do
    {:ok, pid} =
      ExampleOrderBookFeed.start_link(
        feed_id: :example_feed,
        symbols: [:btc_usd, :ltc_usd]
      )

    log_msg =
      capture_log(fn ->
        WebSocket.send_msg(pid, "close")

        assert_receive :disconnected
      end)

    assert log_msg =~ "[error] disconnected - reason: {:remote, 1000, \"\"}"
  end
end
