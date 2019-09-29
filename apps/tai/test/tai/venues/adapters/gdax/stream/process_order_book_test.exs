defmodule Tai.VenueAdapters.Gdax.Stream.ProcessOrderBookTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.Gdax.Stream.ProcessOrderBook
  alias Tai.Markets.OrderBook

  @venue :venue_a
  @symbol :btc_usd
  @venue_symbol "BTC-USD"
  @process_quote_name Tai.Markets.ProcessQuote.to_name(@venue, @symbol)
  @product struct(Tai.Venues.Product,
             venue_id: @venue,
             symbol: @symbol,
             venue_symbol: @venue_symbol
           )

  setup do
    {:ok, _} = Application.ensure_all_started(:tzdata)
    start_supervised!({Tai.PubSub, 1})
    start_supervised!({Tai.Events, 1})
    start_supervised!({OrderBook, @product})
    {:ok, pid} = start_supervised({ProcessOrderBook, @product})
    Process.register(self(), @process_quote_name)

    {:ok, %{pid: pid}}
  end

  test "can snapshot the order book", %{pid: pid} do
    data = %{
      "bids" => [["100.0", "5.0"]],
      "asks" => [["101.0", "10.0"]]
    }

    GenServer.cast(pid, {:snapshot, data, Timex.now()})

    assert_receive {:"$gen_cast", {:order_book_snapshot, forwarded_order_book, change_set}}

    assert Enum.count(forwarded_order_book.bids) == 1
    assert forwarded_order_book.bids == %{100.0 => 5.0}
    assert Enum.count(forwarded_order_book.asks) == 1
    assert forwarded_order_book.asks == %{101.0 => 10.0}
  end

  test "can insert price points into the order book", %{pid: pid} do
    Tai.Events.firehose_subscribe()

    data = %{
      "changes" => [
        ["buy", "100.0", "5.0"],
        ["sell", "101.0", "10.0"]
      ],
      "time" => "2019-09-22T23:45:34.836816Z"
    }

    GenServer.cast(pid, {:update, data, Timex.now()})

    assert_receive {:"$gen_cast", {:order_book_apply, forwarded_order_book, change_set}}

    assert Enum.count(forwarded_order_book.bids) == 1
    assert forwarded_order_book.bids == %{100.0 => 5.0}
    assert Enum.count(forwarded_order_book.asks) == 1
    assert forwarded_order_book.asks == %{101.0 => 10.0}
  end

  test "can update existing price points in the order book", %{pid: pid} do
    snapshot =
      struct(OrderBook.ChangeSet,
        venue: @venue,
        symbol: @symbol,
        changes: [
          {:upsert, :bid, 100.0, 5.0},
          {:upsert, :ask, 101.0, 10.0}
        ]
      )

    OrderBook.replace(snapshot)

    data = %{
      "changes" => [
        ["buy", "100.0", "15.0"],
        ["sell", "101.0", "11.0"]
      ],
      "time" => "2019-09-22T23:45:34.836816Z"
    }

    GenServer.cast(pid, {:update, data, Timex.now()})

    assert_receive {:"$gen_cast", {:order_book_apply, forwarded_order_book, change_set}}

    assert Enum.count(forwarded_order_book.bids) == 1
    assert forwarded_order_book.bids == %{100.0 => 15.0}
    assert Enum.count(forwarded_order_book.asks) == 1
    assert forwarded_order_book.asks == %{101.0 => 11.0}

    assert %DateTime{} = forwarded_order_book.last_venue_timestamp
    assert %DateTime{} = forwarded_order_book.last_received_at
  end

  test "can delete existing price points from the order book", %{pid: pid} do
    snapshot =
      struct(OrderBook.ChangeSet,
        venue: @venue,
        symbol: @symbol,
        changes: [
          {:upsert, :bid, 100.0, 5.0},
          {:upsert, :ask, 101.0, 10.0}
        ]
      )

    OrderBook.replace(snapshot)

    data = %{
      "changes" => [
        ["buy", "100.0", "0.0"],
        ["sell", "101.0", "0"]
      ],
      "time" => "2019-09-22T23:45:34.836816Z"
    }

    GenServer.cast(pid, {:update, data, Timex.now()})

    assert_receive {:"$gen_cast", {:order_book_apply, forwarded_order_book, change_set}}

    assert Enum.count(forwarded_order_book.bids) == 0
    assert Enum.count(forwarded_order_book.asks) == 0

    assert %DateTime{} = forwarded_order_book.last_venue_timestamp
    assert %DateTime{} = forwarded_order_book.last_received_at
  end
end
