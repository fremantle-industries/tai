defmodule Tai.ExchangeAdapters.Binance.OrderBookFeedTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Binance.OrderBookFeed

  alias Tai.ExchangeAdapters.Binance.OrderBookFeed
  alias Tai.Markets.{OrderBook}

  defmodule Subscriber do
    use GenServer

    def start_link, do: GenServer.start_link(__MODULE__, :ok)
    def init(state), do: {:ok, state}
    def subscribe_to_order_book_changes do
      Tai.PubSub.subscribe({:order_book_changes, :my_binance_feed})
    end
    def subscribe_to_order_book_snapshot do
      Tai.PubSub.subscribe({:order_book_snapshot, :my_binance_feed})
    end
    def unsubscribe_from_order_book_changes do
      Tai.PubSub.unsubscribe({:order_book_changes, :my_binance_feed})
    end
    def unsubscribe_from_order_book_snapshot do
      Tai.PubSub.unsubscribe({:order_book_snapshot, :my_binance_feed})
    end

    def handle_info({:order_book_changes, _feed_id, _symbol, _changes} = msg, state) do
      send :test, msg
      {:noreply, state}
    end
    def handle_info({:order_book_snapshot, _feed_id, _symbol, _snapshot} = msg, state) do
      send :test, msg
      {:noreply, state}
    end
  end

  def send_feed_msg(pid, msg) do
    WebSockex.send_frame(pid, {:text, msg |> JSON.encode!})
  end

  defp send_depth_update(pid, binance_symbol, changed_bids, changed_asks) do
    send_feed_msg(
      pid,
      %{
        data: %{
          e: "depthUpdate",
          E: Timex.now |> DateTime.to_unix(:millisecond),
          s: binance_symbol,
          b: changed_bids,
          a: changed_asks,
          U: 1,
          u: 2
        },
        stream: "foo@bar"
      }
    )
  end

  setup do
    HTTPoison.start
    ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes/exchange_adapters/binance")

    my_binance_feed_btcusdt_pid = start_supervised!({OrderBook, [feed_id: :my_binance_feed, symbol: :btcusdt]}, id: :my_binance_feed_btcusdt)
    my_binance_feed_ltcusdt_pid = start_supervised!({OrderBook, [feed_id: :my_binance_feed, symbol: :ltcusdt]}, id: :my_binance_feed_ltcusdt)
    my_feed_b_btcusdt_pid = start_supervised!({OrderBook, [feed_id: :my_feed_b, symbol: :btcusdt]}, id: :my_feed_b_btcusdt)

    {:ok, my_binance_feed_pid} = use_cassette "order_book_feed" do
      OrderBookFeed.start_link(
        "ws://localhost:#{EchoBoy.Config.port}/ws",
        feed_id: :my_binance_feed,
        symbols: [:btcusdt, :ltcusdt]
      )
    end

    OrderBook.replace(
      my_binance_feed_ltcusdt_pid,
      %{
        bids: %{100.0 => {0.1, nil, nil}},
        asks: %{100.1 => {0.1, nil, nil}}
      }
    )
    OrderBook.replace(
      my_feed_b_btcusdt_pid,
      %{
        bids: %{1.0 => {1.1, nil, nil}},
        asks: %{1.2 => {0.1, nil, nil}}
      }
    )

    {
      :ok,
      %{
        my_binance_feed_pid: my_binance_feed_pid,
        my_binance_feed_btcusdt_pid: my_binance_feed_btcusdt_pid,
        my_binance_feed_ltcusdt_pid: my_binance_feed_ltcusdt_pid,
        my_feed_b_btcusdt_pid: my_feed_b_btcusdt_pid
      }
    }
  end

  test(
    "depthUpdate adds/updates/deletes the bids/asks in the order book for the symbol",
    %{
      my_binance_feed_pid: my_binance_feed_pid,
      my_binance_feed_btcusdt_pid: my_binance_feed_btcusdt_pid,
      my_binance_feed_ltcusdt_pid: my_binance_feed_ltcusdt_pid,
      my_feed_b_btcusdt_pid: my_feed_b_btcusdt_pid
    }
  ) do
    assert {:ok, %{bids: bids, asks: asks}} = OrderBook.quotes(my_binance_feed_btcusdt_pid)
    assert [
      [price: 8541.0, size: 1.174739, processed_at: _, server_changed_at: nil],
      [price: 8536.17, size: 0.036, processed_at: _, server_changed_at: nil],
      [price: 8536.16, size: 0.158082, processed_at: _, server_changed_at: nil],
      [price: 8536.14, size: 0.003345, processed_at: _, server_changed_at: nil],
      [price: 8535.97, size: 0.024218, processed_at: _, server_changed_at: nil]
    ] = bids
    assert [
      [price: 8555.57, size: 0.039, processed_at: _, server_changed_at: nil],
      [price: 8555.58, size: 0.089469, processed_at: _, server_changed_at: nil],
      [price: 8559.99, size: 0.375128, processed_at: _, server_changed_at: nil],
      [price: 8560.0, size: 0.620366, processed_at: _, server_changed_at: nil],
      [price: 8561.11, size: 12.0, processed_at: _, server_changed_at: nil]
    ] = asks

    send_depth_update(
      my_binance_feed_pid,
      "BTCUSDT",
      [
        ["8541.01", "0.12", []],
        ["8541.0", "2.23", []],
        ["8536.17", "0", []]
      ],
      [
        ["8560.05", "1.13", []],
        ["8555.57", "0", []],
        ["8559.99", "0.22", []],
      ]
    )

    :timer.sleep 100

    assert {:ok, %{bids: bids, asks: asks}} = OrderBook.quotes(my_binance_feed_btcusdt_pid)
    assert [
      [price: 8541.01, size: 0.12, processed_at: _, server_changed_at: bid_server_changed_at_a],
      [price: 8541.0, size: 2.23, processed_at: _, server_changed_at: bid_server_changed_at_b],
      [price: 8536.16, size: 0.158082, processed_at: _, server_changed_at: bid_server_changed_at_c],
      [price: 8536.14, size: 0.003345, processed_at: _, server_changed_at: bid_server_changed_at_d],
      [price: 8535.97, size: 0.024218, processed_at: _, server_changed_at: bid_server_changed_at_e]
    ] = bids
    assert DateTime.compare(bid_server_changed_at_a, bid_server_changed_at_b)
    assert bid_server_changed_at_c == nil
    assert bid_server_changed_at_d == nil
    assert bid_server_changed_at_e == nil

    assert [
      [price: 8555.58, size: 0.089469, processed_at: _, server_changed_at: ask_server_changed_at_a],
      [price: 8559.99, size: 0.22, processed_at: _, server_changed_at: ask_server_changed_at_b],
      [price: 8560.0, size: 0.620366, processed_at: _, server_changed_at: ask_server_changed_at_c],
      [price: 8560.05, size: 1.13, processed_at: _, server_changed_at: ask_server_changed_at_d],
      [price: 8561.11, size: 12.0, processed_at: _, server_changed_at: ask_server_changed_at_e]
    ] = asks
    assert DateTime.compare(ask_server_changed_at_b, ask_server_changed_at_d)
    assert ask_server_changed_at_a == nil
    assert ask_server_changed_at_c == nil
    assert ask_server_changed_at_e == nil

    assert OrderBook.quotes(my_binance_feed_ltcusdt_pid) == {
      :ok,
      %{
        bids: [[price: 100.0, size: 0.1, processed_at: nil, server_changed_at: nil]],
        asks: [[price: 100.1, size: 0.1, processed_at: nil, server_changed_at: nil]]
      }
    }
    assert OrderBook.quotes(my_feed_b_btcusdt_pid) == {
      :ok,
      %{
        bids: [[price: 1.0, size: 1.1, processed_at: nil, server_changed_at: nil]],
        asks: [[price: 1.2, size: 0.1, processed_at: nil, server_changed_at: nil]]
      }
    }
  end

  test(
    "broadcasts the order book changes to the pubsub subscribers",
    %{my_binance_feed_pid: my_binance_feed_pid}
  ) do
    {:ok, _} = Subscriber.start_link()
    Subscriber.subscribe_to_order_book_changes()

    send_depth_update(
      my_binance_feed_pid,
      "BTCUSDT",
      [["8541.01", "0.12", []]],
      []
    )

    assert_receive {
      :order_book_changes,
      :my_binance_feed,
      :btcusdt,
      %{
        bids: %{8541.01 => {0.12, _, _}},
        asks: %{}
      }
    }
    Subscriber.unsubscribe_from_order_book_changes()
  end
end
