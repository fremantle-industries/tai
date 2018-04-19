defmodule Tai.ExchangeAdapters.Poloniex.OrderBookFeedTest do
  use ExUnit.Case
  doctest Tai.ExchangeAdapters.Poloniex.OrderBookFeed

  import ExUnit.CaptureLog

  alias Tai.{ExchangeAdapters.Poloniex.OrderBookFeed, WebSocket}
  alias Tai.Markets.{OrderBook, PriceLevel}

  @currency_pair_channel_id_mappings %{
    "USDT_BTC" => 121
  }

  def send_feed_order_book_change(pid, currency_pair, changes) do
    WebSocket.send_json_msg(pid, [@currency_pair_channel_id_mappings[currency_pair], 2, changes])
  end

  defp send_feed_snapshot(pid, currency_pair, bids, asks) do
    WebSocket.send_json_msg(pid, [
      @currency_pair_channel_id_mappings[currency_pair],
      2,
      [
        [
          "i",
          %{
            "currencyPair" => currency_pair,
            "orderBook" => [asks, bids]
          }
        ]
      ]
    ])
  end

  setup do
    Process.register(self(), :test)

    my_poloniex_feed_btcusd_pid =
      start_supervised!(
        {OrderBook, [feed_id: :my_poloniex_feed, symbol: :btcusdt]},
        id: :my_poloniex_feed_btcusdt
      )

    my_poloniex_feed_ltcusd_pid =
      start_supervised!(
        {OrderBook, [feed_id: :my_poloniex_feed, symbol: :ltcusdt]},
        id: :my_poloniex_feed_ltcusdt
      )

    my_feed_b_btcusd_pid =
      start_supervised!(
        {OrderBook, [feed_id: :my_feed_b, symbol: :btcusdt]},
        id: :my_feed_b_btcusdt
      )

    {:ok, my_poloniex_feed_pid} =
      OrderBookFeed.start_link(
        "ws://localhost:#{EchoBoy.Config.port()}/ws",
        feed_id: :my_poloniex_feed,
        symbols: [:btcusd, :ltcusd]
      )

    OrderBook.replace(my_poloniex_feed_ltcusd_pid, %OrderBook{
      bids: %{100.0 => {0.1, nil, nil}},
      asks: %{100.1 => {0.1, nil, nil}}
    })

    OrderBook.replace(my_feed_b_btcusd_pid, %OrderBook{
      bids: %{1.0 => {1.1, nil, nil}},
      asks: %{1.2 => {0.1, nil, nil}}
    })

    start_supervised!({
      Support.ForwardOrderBookEvents,
      [feed_id: :my_poloniex_feed, symbol: :btcusdt]
    })

    {
      :ok,
      %{
        my_poloniex_feed_pid: my_poloniex_feed_pid,
        my_poloniex_feed_btcusd_pid: my_poloniex_feed_btcusd_pid,
        my_poloniex_feed_ltcusd_pid: my_poloniex_feed_ltcusd_pid,
        my_feed_b_btcusd_pid: my_feed_b_btcusd_pid
      }
    }
  end

  test("initialization replaces the bids/asks in the order book for the symbol", %{
    my_poloniex_feed_pid: my_poloniex_feed_pid,
    my_poloniex_feed_btcusd_pid: my_poloniex_feed_btcusd_pid,
    my_poloniex_feed_ltcusd_pid: my_poloniex_feed_ltcusd_pid,
    my_feed_b_btcusd_pid: my_feed_b_btcusd_pid
  }) do
    send_feed_snapshot(
      my_poloniex_feed_pid,
      "USDT_BTC",
      %{"110.0" => "100.0", "100.0" => "110.0"},
      %{
        "120.0" => "10.0",
        "130.0" => "11.0"
      }
    )

    assert_receive {:order_book_snapshot, :my_poloniex_feed, :btcusdt, %OrderBook{}}
    assert {:ok, p_btcusd_book} = OrderBook.quotes(my_poloniex_feed_btcusd_pid)

    assert [
             %PriceLevel{price: 110.0, size: 100.0, server_changed_at: nil} = bid_a,
             %PriceLevel{price: 100.0, size: 110.0, server_changed_at: nil} = bid_b
           ] = p_btcusd_book.bids

    assert [
             %PriceLevel{price: 120.0, size: 10.0, server_changed_at: nil} = ask_a,
             %PriceLevel{price: 130.0, size: 11.0, server_changed_at: nil} = ask_b
           ] = p_btcusd_book.asks

    assert DateTime.compare(bid_a.processed_at, bid_b.processed_at)
    assert DateTime.compare(bid_a.processed_at, ask_a.processed_at)
    assert DateTime.compare(bid_a.processed_at, ask_b.processed_at)

    assert {:ok, p_ltcusd_book} = OrderBook.quotes(my_poloniex_feed_ltcusd_pid)
    assert p_ltcusd_book.bids == [%PriceLevel{price: 100.0, size: 0.1, processed_at: nil}]
    assert p_ltcusd_book.asks == [%PriceLevel{price: 100.1, size: 0.1, processed_at: nil}]

    assert {:ok, b_btcusd_book} = OrderBook.quotes(my_feed_b_btcusd_pid)

    assert b_btcusd_book.bids == [%PriceLevel{price: 1.0, size: 1.1, processed_at: nil}]
    assert b_btcusd_book.asks == [%PriceLevel{price: 1.2, size: 0.1, processed_at: nil}]
  end

  test("order book changes adds/updates/deletes the bids/asks", %{
    my_poloniex_feed_pid: my_poloniex_feed_pid,
    my_poloniex_feed_btcusd_pid: my_poloniex_feed_btcusd_pid,
    my_poloniex_feed_ltcusd_pid: my_poloniex_feed_ltcusd_pid,
    my_feed_b_btcusd_pid: my_feed_b_btcusd_pid
  }) do
    send_feed_snapshot(
      my_poloniex_feed_pid,
      "USDT_BTC",
      %{},
      %{}
    )

    assert_receive {:order_book_snapshot, :my_poloniex_feed, :btcusdt, %OrderBook{}}

    send_feed_order_book_change(my_poloniex_feed_pid, "USDT_BTC", [
      ["o", 1, "0.9", "0.1"],
      ["o", 0, "1.4", "0.12"],
      ["o", 1, "1.0", "1.2"],
      ["o", 0, "1.2", "0.11"],
      ["o", 1, "1.1", "0"],
      ["o", 0, "1.3", "0.0"]
    ])

    assert_receive {:order_book_changes, :my_poloniex_feed, :btcusdt, %OrderBook{}}

    assert {:ok, p_btcusd_book} = OrderBook.quotes(my_poloniex_feed_btcusd_pid)

    assert [
             %PriceLevel{price: 1.0, size: 1.2} = bid_a,
             %PriceLevel{price: 0.9, size: 0.1} = bid_b
           ] = p_btcusd_book.bids

    assert [
             %PriceLevel{price: 1.2, size: 0.11} = ask_a,
             %PriceLevel{price: 1.4, size: 0.12} = ask_b
           ] = p_btcusd_book.asks

    assert DateTime.compare(bid_a.processed_at, bid_b.processed_at)
    assert DateTime.compare(bid_a.processed_at, ask_a.processed_at)
    assert DateTime.compare(bid_a.processed_at, ask_b.processed_at)

    assert {:ok, p_ltcusd_book} = OrderBook.quotes(my_poloniex_feed_ltcusd_pid)
    assert p_ltcusd_book.bids == [%PriceLevel{price: 100.0, size: 0.1, processed_at: nil}]
    assert p_ltcusd_book.asks == [%PriceLevel{price: 100.1, size: 0.1, processed_at: nil}]

    assert {:ok, b_btcusd_book} = OrderBook.quotes(my_feed_b_btcusd_pid)
    assert b_btcusd_book.bids == [%PriceLevel{price: 1.0, size: 1.1, processed_at: nil}]
    assert b_btcusd_book.asks == [%PriceLevel{price: 1.2, size: 0.1, processed_at: nil}]
  end

  test "logs a warning for unhandled messages", %{
    my_poloniex_feed_pid: my_poloniex_feed_pid
  } do
    log_msg =
      capture_log(fn ->
        WebSocket.send_json_msg(my_poloniex_feed_pid, %{type: "unknown_type"})
        :timer.sleep(100)
      end)

    assert log_msg =~ "unhandled message: %{\"type\" => \"unknown_type\"}"
  end
end
