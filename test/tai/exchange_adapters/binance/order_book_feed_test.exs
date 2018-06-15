defmodule Tai.ExchangeAdapters.Binance.OrderBookFeedTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Binance.OrderBookFeed

  import ExUnit.CaptureLog

  alias Tai.{ExchangeAdapters.Binance.OrderBookFeed, WebSocket}
  alias Tai.Markets.{OrderBook, PriceLevel}

  defp send_depth_update(pid, binance_symbol, changed_bids, changed_asks) do
    WebSocket.send_json_msg(pid, %{
      data: %{
        e: "depthUpdate",
        E: Timex.now() |> DateTime.to_unix(:millisecond),
        s: binance_symbol,
        b: changed_bids,
        a: changed_asks,
        U: 1,
        u: 2
      },
      stream: "foo@bar"
    })
  end

  setup do
    HTTPoison.start()

    Process.register(self(), :test)

    my_binance_feed_btcusdt_pid =
      start_supervised!(
        {OrderBook, [feed_id: :my_binance_feed, symbol: :btcusdt]},
        id: :my_binance_feed_btcusdt
      )

    my_binance_feed_ltcusdt_pid =
      start_supervised!(
        {OrderBook, [feed_id: :my_binance_feed, symbol: :ltcusdt]},
        id: :my_binance_feed_ltcusdt
      )

    my_feed_b_btcusdt_pid =
      start_supervised!(
        {OrderBook, [feed_id: :my_feed_b, symbol: :btcusdt]},
        id: :my_feed_b_btcusdt
      )

    {:ok, my_binance_feed_pid} =
      use_cassette "exchange_adapters/binance/order_book_feed" do
        OrderBookFeed.start_link(
          "ws://localhost:#{EchoBoy.Config.port()}/ws",
          feed_id: :my_binance_feed,
          symbols: [:btcusdt, :ltcusdt]
        )
      end

    OrderBook.replace(my_binance_feed_ltcusdt_pid, %OrderBook{
      bids: %{100.0 => {0.1, nil, nil}},
      asks: %{100.1 => {0.1, nil, nil}}
    })

    OrderBook.replace(my_feed_b_btcusdt_pid, %OrderBook{
      bids: %{1.0 => {1.1, nil, nil}},
      asks: %{1.2 => {0.1, nil, nil}}
    })

    start_supervised!({
      Support.ForwardOrderBookEvents,
      [feed_id: :my_binance_feed, symbol: :btcusdt]
    })

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

  test("depthUpdate adds/updates/deletes the bids/asks in the order book for the symbol", %{
    my_binance_feed_pid: my_binance_feed_pid,
    my_binance_feed_btcusdt_pid: my_binance_feed_btcusdt_pid,
    my_binance_feed_ltcusdt_pid: my_binance_feed_ltcusdt_pid,
    my_feed_b_btcusdt_pid: my_feed_b_btcusdt_pid
  }) do
    assert {:ok, %{bids: bids, asks: asks}} = OrderBook.quotes(my_binance_feed_btcusdt_pid)

    assert [
             %PriceLevel{price: 8541.0, size: 1.174739, server_changed_at: nil},
             %PriceLevel{price: 8536.17, size: 0.036, server_changed_at: nil},
             %PriceLevel{price: 8536.16, size: 0.158082, server_changed_at: nil},
             %PriceLevel{price: 8536.14, size: 0.003345, server_changed_at: nil},
             %PriceLevel{price: 8535.97, size: 0.024218, server_changed_at: nil}
           ] = bids

    assert [
             %PriceLevel{price: 8555.57, size: 0.039, server_changed_at: nil},
             %PriceLevel{price: 8555.58, size: 0.089469, server_changed_at: nil},
             %PriceLevel{price: 8559.99, size: 0.375128, server_changed_at: nil},
             %PriceLevel{price: 8560.0, size: 0.620366, server_changed_at: nil},
             %PriceLevel{price: 8561.11, size: 12.0, server_changed_at: nil}
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
        ["8559.99", "0.22", []]
      ]
    )

    assert_receive {:order_book_changes, :my_binance_feed, :btcusdt, %OrderBook{}}
    assert {:ok, %{bids: bids, asks: asks}} = OrderBook.quotes(my_binance_feed_btcusdt_pid)

    assert [
             %PriceLevel{price: 8541.01, size: 0.12} = bid_a,
             %PriceLevel{price: 8541.0, size: 2.23} = bid_b,
             %PriceLevel{price: 8536.16, size: 0.158082} = bid_c,
             %PriceLevel{price: 8536.14, size: 0.003345} = bid_d,
             %PriceLevel{price: 8535.97, size: 0.024218} = bid_e
           ] = bids

    assert DateTime.compare(bid_a.server_changed_at, bid_b.server_changed_at)
    assert bid_c.server_changed_at == nil
    assert bid_d.server_changed_at == nil
    assert bid_e.server_changed_at == nil

    assert [
             %PriceLevel{price: 8555.58, size: 0.089469} = ask_a,
             %PriceLevel{price: 8559.99, size: 0.22} = ask_b,
             %PriceLevel{price: 8560.0, size: 0.620366} = ask_c,
             %PriceLevel{price: 8560.05, size: 1.13} = ask_d,
             %PriceLevel{price: 8561.11, size: 12.0} = ask_e
           ] = asks

    assert DateTime.compare(ask_b.server_changed_at, ask_d.server_changed_at)
    assert ask_a.server_changed_at == nil
    assert ask_c.server_changed_at == nil
    assert ask_e.server_changed_at == nil

    assert OrderBook.quotes(my_binance_feed_ltcusdt_pid) == {
             :ok,
             %OrderBook{
               bids: [
                 %PriceLevel{price: 100.0, size: 0.1, processed_at: nil, server_changed_at: nil}
               ],
               asks: [
                 %PriceLevel{price: 100.1, size: 0.1, processed_at: nil, server_changed_at: nil}
               ]
             }
           }

    assert OrderBook.quotes(my_feed_b_btcusdt_pid) == {
             :ok,
             %OrderBook{
               bids: [
                 %PriceLevel{price: 1.0, size: 1.1, processed_at: nil, server_changed_at: nil}
               ],
               asks: [
                 %PriceLevel{price: 1.2, size: 0.1, processed_at: nil, server_changed_at: nil}
               ]
             }
           }
  end

  test "logs a warning for invalid symbols" do
    use_cassette "exchange_adapters/binance/order_book_feed_invalid_symbol_error" do
      log_msg =
        capture_log(fn ->
          {:error, _reason} =
            OrderBookFeed.start_link(
              "ws://localhost:#{EchoBoy.Config.port()}/ws",
              feed_id: :my_binance_feed_invalid_symbol,
              symbols: [:idontexist, :wedontexist]
            )

          :timer.sleep(100)
        end)

      assert log_msg =~
               "[warn]  could not subscribe to order books with invalid symbols: idontexist, wedontexist"
    end
  end
end
