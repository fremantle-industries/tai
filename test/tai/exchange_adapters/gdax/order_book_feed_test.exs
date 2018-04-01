defmodule Tai.ExchangeAdapters.Gdax.OrderBookFeedTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Gdax.OrderBookFeed

  import ExUnit.CaptureLog

  alias Tai.ExchangeAdapters.Gdax.OrderBookFeed
  alias Tai.Markets.{OrderBook, PriceLevel}

  defmodule Subscriber do
    use GenServer

    def start_link(_), do: GenServer.start_link(__MODULE__, :ok)
    def init(state), do: {:ok, state}
    def subscribe_to_order_book_changes do
      Tai.PubSub.subscribe({:order_book_changes, :my_feed_a, :btcusd})
    end
    def subscribe_to_order_book_snapshot do
      Tai.PubSub.subscribe({:order_book_snapshot, :my_feed_a, :btcusd})
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

  def send_feed_l2update(pid, product_id, changes) do
    send_feed_msg(
      pid,
      %{
        type: "l2update",
        time: Timex.now |> DateTime.to_string,
        product_id: product_id,
        changes: changes
      }
    )
  end

  def send_feed_snapshot(pid, product_id, bids, asks) do
    send_feed_msg(
      pid,
      %{
        type: "snapshot",
        product_id: product_id,
        bids: bids,
        asks: asks
      }
    )
  end

  setup do
    HTTPoison.start
    ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes/exchange_adapters/gdax")

    my_feed_a_btcusd_pid = start_supervised!({OrderBook, [feed_id: :my_feed_a, symbol: :btcusd]}, id: :my_feed_a_btcusd)
    my_feed_a_ltcusd_pid = start_supervised!({OrderBook, [feed_id: :my_feed_a, symbol: :ltcusd]}, id: :my_feed_a_ltcusd)
    my_feed_b_btcusd_pid = start_supervised!({OrderBook, [feed_id: :my_feed_b, symbol: :btcusd]}, id: :my_feed_b_btcusd)

    {:ok, my_feed_a_pid} = use_cassette "order_book_feed" do
      OrderBookFeed.start_link(
        "ws://localhost:#{EchoBoy.Config.port}/ws",
        feed_id: :my_feed_a,
        symbols: [:btcusd, :ltcusd]
      )
    end

    OrderBook.replace(
      my_feed_a_btcusd_pid,
      %OrderBook{
        bids: %{
          1.0 => {1.1, nil, nil},
          1.1 => {1.0, nil, nil}
        },
        asks: %{
          1.2 => {0.1, nil, nil},
          1.3 => {0.11, nil, nil}
        }
      }
    )
    OrderBook.replace(
      my_feed_a_ltcusd_pid,
      %OrderBook{
        bids: %{100.0 => {0.1, nil, nil}},
        asks: %{100.1 => {0.1, nil, nil}}
      }
    )
    OrderBook.replace(
      my_feed_b_btcusd_pid,
      %OrderBook{
        bids: %{1.0 => {1.1, nil, nil}},
        asks: %{1.2 => {0.1, nil, nil}}
      }
    )

    {
      :ok,
      %{
        my_feed_a_pid: my_feed_a_pid,
        my_feed_a_btcusd_pid: my_feed_a_btcusd_pid,
        my_feed_a_ltcusd_pid: my_feed_a_ltcusd_pid,
        my_feed_b_btcusd_pid: my_feed_b_btcusd_pid
      }
    }
  end

  test(
    "snapshot replaces the bids/asks in the order book for the symbol",
    %{
      my_feed_a_pid: my_feed_a_pid,
      my_feed_a_btcusd_pid: my_feed_a_btcusd_pid,
      my_feed_a_ltcusd_pid: my_feed_a_ltcusd_pid,
      my_feed_b_btcusd_pid: my_feed_b_btcusd_pid
    }
  ) do
    send_feed_msg(
      my_feed_a_pid,
      %{
        type: "snapshot",
        product_id: "BTC-USD",
        bids: [["110.0", "100.0"], ["100.0", "110.0"]],
        asks: [["120.0", "10.0"], ["130.0", "11.0"]]
      }
    )

    :timer.sleep 100
    {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(my_feed_a_btcusd_pid)
    [
      %PriceLevel{price: 110.0, size: 100.0, server_changed_at: nil} = bid_a,
      %PriceLevel{price: 100.0, size: 110.0, server_changed_at: nil} = bid_b
    ] = bids
    [
      %PriceLevel{price: 120.0, size: 10.0, server_changed_at: nil} = ask_a,
      %PriceLevel{price: 130.0, size: 11.0, server_changed_at: nil} = ask_b
    ] = asks
    assert DateTime.compare(bid_a.processed_at, bid_b.processed_at)
    assert DateTime.compare(bid_a.processed_at, ask_a.processed_at)
    assert DateTime.compare(bid_a.processed_at, ask_b.processed_at)

    assert OrderBook.quotes(my_feed_a_ltcusd_pid) == {
      :ok,
      %OrderBook{
        bids: [%PriceLevel{price: 100.0, size: 0.1, processed_at: nil, server_changed_at: nil}],
        asks: [%PriceLevel{price: 100.1, size: 0.1, processed_at: nil, server_changed_at: nil}]
      }
    }

    assert OrderBook.quotes(my_feed_b_btcusd_pid) == {
      :ok,
      %OrderBook{
        bids: [%PriceLevel{price: 1.0, size: 1.1, processed_at: nil, server_changed_at: nil}],
        asks: [%PriceLevel{price: 1.2, size: 0.1, processed_at: nil, server_changed_at: nil}]
      }
    }
  end

  test(
    "l2update adds/updates/deletes the bids/asks in the order book for the symbol",
    %{
      my_feed_a_pid: my_feed_a_pid,
      my_feed_a_btcusd_pid: my_feed_a_btcusd_pid,
      my_feed_a_ltcusd_pid: my_feed_a_ltcusd_pid,
      my_feed_b_btcusd_pid: my_feed_b_btcusd_pid
    }
  ) do
    send_feed_l2update(
      my_feed_a_pid,
      "BTC-USD", 
      [
        ["buy", "0.9", "0.1"],
        ["sell", "1.4", "0.12"],
        ["buy", "1.0", "1.2"],
        ["sell", "1.2", "0.11"],
        ["buy", "1.1", "0"],
        ["sell", "1.3", "0.0"]
      ]
    )

    :timer.sleep 100
    {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(my_feed_a_btcusd_pid)
    [%PriceLevel{price: 1.0, size: 1.2} = bid_a, %PriceLevel{price: 0.9, size: 0.1} = bid_b] = bids
    [%PriceLevel{price: 1.2, size: 0.11} = ask_a, %PriceLevel{price: 1.4, size: 0.12} = ask_b] = asks
    assert DateTime.compare(bid_a.processed_at, bid_b.processed_at)
    assert DateTime.compare(bid_a.processed_at, ask_a.processed_at)
    assert DateTime.compare(bid_a.processed_at, ask_b.processed_at)
    assert DateTime.compare(bid_a.server_changed_at, bid_b.server_changed_at)
    assert DateTime.compare(bid_a.server_changed_at, ask_a.server_changed_at)
    assert DateTime.compare(bid_a.server_changed_at, ask_b.server_changed_at)

    assert OrderBook.quotes(my_feed_a_ltcusd_pid) == {
      :ok,
      %OrderBook{
        bids: [%PriceLevel{price: 100.0, size: 0.1, processed_at: nil, server_changed_at: nil}],
        asks: [%PriceLevel{price: 100.1, size: 0.1, processed_at: nil, server_changed_at: nil}]
      }
    }

    assert OrderBook.quotes(my_feed_b_btcusd_pid) == {
      :ok,
      %OrderBook{
        bids: [%PriceLevel{price: 1.0, size: 1.1, processed_at: nil, server_changed_at: nil}],
        asks: [%PriceLevel{price: 1.2, size: 0.1, processed_at: nil, server_changed_at: nil}]
      }
    }
  end

  test(
    "broadcasts the order book changes to the pubsub subscribers",
    %{my_feed_a_pid: my_feed_a_pid}
  ) do
    start_supervised!(Subscriber)
    Subscriber.subscribe_to_order_book_changes()

    send_feed_l2update(
      my_feed_a_pid,
      "BTC-USD",
      [["buy", "0.9", "0.1"]]
    )

    assert_receive {
      :order_book_changes,
      :my_feed_a,
      :btcusd,
      %OrderBook{
        bids: %{0.9 => {0.1, _processed_at, _server_changed_at}},
        asks: %{}
      }
    }
  end


  test "logs a warning for unhandled messages", %{my_feed_a_pid: my_feed_a_pid} do
    assert capture_log(fn ->
      WebSockex.send_frame(my_feed_a_pid, {:text, %{type: "unknown_type"} |> JSON.encode!})
      :timer.sleep 100
    end) =~ "[order_book_feed_my_feed_a] unhandled message: %{\"type\" => \"unknown_type\"}"
  end
end
