defmodule Tai.Venues.Adapters.Gdax.OrderBookFeedTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import ExUnit.CaptureLog

  def send_feed_l2update(pid, product_id, changes) do
    Tai.WebSocket.send_json_msg(pid, %{
      type: "l2update",
      time: Timex.now() |> DateTime.to_string(),
      product_id: product_id,
      changes: changes
    })
  end

  def send_feed_snapshot(pid, product_id, bids, asks) do
    Tai.WebSocket.send_json_msg(pid, %{
      type: "snapshot",
      product_id: product_id,
      bids: bids,
      asks: asks
    })
  end

  def send_subscriptions(pid, product_ids) do
    Tai.WebSocket.send_json_msg(pid, %{
      type: "subscriptions",
      channels: [
        %{
          product_ids: product_ids,
          name: "level2"
        }
      ]
    })
  end

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    HTTPoison.start()
    Process.register(self(), :test)

    my_gdax_feed_btc_usd_pid =
      start_supervised!(
        {Tai.Markets.OrderBook, [feed_id: :my_gdax_feed, symbol: :btc_usd]},
        id: :my_gdax_feed_btc_usd
      )

    my_gdax_feed_ltc_usd_pid =
      start_supervised!(
        {Tai.Markets.OrderBook, [feed_id: :my_gdax_feed, symbol: :ltc_usd]},
        id: :my_gdax_feed_ltc_usd
      )

    my_feed_b_btc_usd_pid =
      start_supervised!(
        {Tai.Markets.OrderBook, [feed_id: :my_feed_b, symbol: :btc_usd]},
        id: :my_feed_b_btc_usd
      )

    {:ok, my_gdax_feed_pid} =
      use_cassette "venue_adapters/gdax/order_book_feed" do
        Tai.VenueAdapters.Gdax.OrderBookFeed.start_link(
          "ws://localhost:#{EchoBoy.Config.port()}/ws",
          feed_id: :my_gdax_feed,
          symbols: [:btc_usd, :ltc_usd]
        )
      end

    Tai.Markets.OrderBook.replace(%Tai.Markets.OrderBook{
      venue_id: :my_gdax_feed,
      product_symbol: :btc_usd,
      bids: %{
        1.0 => 1.1,
        1.1 => 1.0
      },
      asks: %{
        1.2 => 0.1,
        1.3 => 0.11
      }
    })

    Tai.Markets.OrderBook.replace(%Tai.Markets.OrderBook{
      venue_id: :my_gdax_feed,
      product_symbol: :ltc_usd,
      bids: %{100.0 => 0.1},
      asks: %{100.1 => 0.1}
    })

    Tai.Markets.OrderBook.replace(%Tai.Markets.OrderBook{
      venue_id: :my_feed_b,
      product_symbol: :btc_usd,
      bids: %{1.0 => 1.1},
      asks: %{1.2 => 0.1}
    })

    start_supervised!({
      Support.ForwardOrderBookEvents,
      [feed_id: :my_gdax_feed, symbol: :btc_usd]
    })

    {
      :ok,
      %{
        my_gdax_feed_pid: my_gdax_feed_pid,
        my_gdax_feed_btc_usd_pid: my_gdax_feed_btc_usd_pid,
        my_gdax_feed_ltc_usd_pid: my_gdax_feed_ltc_usd_pid,
        my_feed_b_btc_usd_pid: my_feed_b_btc_usd_pid
      }
    }
  end

  test("snapshot replaces the bids/asks in the order book for the symbol", %{
    my_gdax_feed_pid: my_gdax_feed_pid,
    my_gdax_feed_btc_usd_pid: my_gdax_feed_btc_usd_pid,
    my_gdax_feed_ltc_usd_pid: my_gdax_feed_ltc_usd_pid,
    my_feed_b_btc_usd_pid: my_feed_b_btc_usd_pid
  }) do
    send_feed_snapshot(my_gdax_feed_pid, "BTC-USD", [["110.0", "100.0"], ["100.0", "110.0"]], [
      ["120.0", "10.0"],
      ["130.0", "11.0"]
    ])

    assert_receive {:order_book_snapshot, :my_gdax_feed, :btc_usd, %Tai.Markets.OrderBook{}}

    {:ok, %Tai.Markets.OrderBook{bids: bids, asks: asks}} =
      Tai.Markets.OrderBook.quotes(my_gdax_feed_btc_usd_pid)

    [
      %Tai.Markets.PricePoint{price: 110.0, size: 100.0},
      %Tai.Markets.PricePoint{price: 100.0, size: 110.0}
    ] = bids

    [
      %Tai.Markets.PricePoint{price: 120.0, size: 10.0},
      %Tai.Markets.PricePoint{price: 130.0, size: 11.0}
    ] = asks

    assert Tai.Markets.OrderBook.quotes(my_gdax_feed_ltc_usd_pid) == {
             :ok,
             %Tai.Markets.OrderBook{
               venue_id: :my_gdax_feed,
               product_symbol: :ltc_usd,
               bids: [
                 %Tai.Markets.PricePoint{price: 100.0, size: 0.1}
               ],
               asks: [
                 %Tai.Markets.PricePoint{price: 100.1, size: 0.1}
               ]
             }
           }

    assert Tai.Markets.OrderBook.quotes(my_feed_b_btc_usd_pid) == {
             :ok,
             %Tai.Markets.OrderBook{
               venue_id: :my_feed_b,
               product_symbol: :btc_usd,
               bids: [
                 %Tai.Markets.PricePoint{price: 1.0, size: 1.1}
               ],
               asks: [
                 %Tai.Markets.PricePoint{price: 1.2, size: 0.1}
               ]
             }
           }
  end

  test("l2update adds/updates/deletes the bids/asks in the order book for the symbol", %{
    my_gdax_feed_pid: my_gdax_feed_pid,
    my_gdax_feed_btc_usd_pid: my_gdax_feed_btc_usd_pid,
    my_gdax_feed_ltc_usd_pid: my_gdax_feed_ltc_usd_pid,
    my_feed_b_btc_usd_pid: my_feed_b_btc_usd_pid
  }) do
    send_feed_l2update(my_gdax_feed_pid, "BTC-USD", [
      ["buy", "0.9", "0.1"],
      ["sell", "1.4", "0.12"],
      ["buy", "1.0", "1.2"],
      ["sell", "1.2", "0.11"],
      ["buy", "1.1", "0"],
      ["sell", "1.3", "0.0"]
    ])

    assert_receive {:order_book_changes, :my_gdax_feed, :btc_usd, %Tai.Markets.OrderBook{}}

    {:ok, %Tai.Markets.OrderBook{bids: bids, asks: asks}} =
      Tai.Markets.OrderBook.quotes(my_gdax_feed_btc_usd_pid)

    [
      %Tai.Markets.PricePoint{price: 1.0, size: 1.2},
      %Tai.Markets.PricePoint{price: 0.9, size: 0.1}
    ] = bids

    [
      %Tai.Markets.PricePoint{price: 1.2, size: 0.11},
      %Tai.Markets.PricePoint{price: 1.4, size: 0.12}
    ] = asks

    assert Tai.Markets.OrderBook.quotes(my_gdax_feed_ltc_usd_pid) == {
             :ok,
             %Tai.Markets.OrderBook{
               venue_id: :my_gdax_feed,
               product_symbol: :ltc_usd,
               bids: [
                 %Tai.Markets.PricePoint{price: 100.0, size: 0.1}
               ],
               asks: [
                 %Tai.Markets.PricePoint{price: 100.1, size: 0.1}
               ]
             }
           }

    assert Tai.Markets.OrderBook.quotes(my_feed_b_btc_usd_pid) == {
             :ok,
             %Tai.Markets.OrderBook{
               venue_id: :my_feed_b,
               product_symbol: :btc_usd,
               bids: [
                 %Tai.Markets.PricePoint{price: 1.0, size: 1.1}
               ],
               asks: [
                 %Tai.Markets.PricePoint{price: 1.2, size: 0.1}
               ]
             }
           }
  end

  test "logs an info message for successful product subscriptions", %{
    my_gdax_feed_pid: my_gdax_feed_pid
  } do
    log_msg =
      capture_log(fn ->
        send_subscriptions(my_gdax_feed_pid, ["BTC-USD", "LTC-USD"])
        :timer.sleep(100)
      end)

    assert log_msg =~ "[info]  successfully subscribed to [\"BTC-USD\", \"LTC-USD\"]"
  end

  test "logs a warning for unhandled messages", %{my_gdax_feed_pid: my_gdax_feed_pid} do
    log_msg =
      capture_log(fn ->
        Tai.WebSocket.send_json_msg(my_gdax_feed_pid, %{type: "unknown_type"})
        :timer.sleep(100)
      end)

    assert log_msg =~ "[warn]  unhandled message: %{\"type\" => \"unknown_type\"}"
  end
end
