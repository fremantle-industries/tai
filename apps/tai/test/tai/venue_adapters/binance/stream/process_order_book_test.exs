defmodule Tai.VenueAdapters.Binance.Stream.ProcessOrderBookTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.Binance.Stream.ProcessOrderBook
  alias Tai.Markets.OrderBook

  @venue :venue_a
  @symbol :xbtusd
  @venue_symbol "XBTUSD"
  @process_quote_name Tai.Markets.ProcessQuote.to_name(@venue, @symbol)
  @product struct(Tai.Venues.Product,
             venue_id: @venue,
             symbol: @symbol,
             venue_symbol: @venue_symbol
           )

  setup do
    Process.register(self(), @process_quote_name)
    start_supervised!({Tai.PubSub, 1})
    start_supervised!({Tai.Events, 1})
    start_supervised!(OrderBook.child_spec(@product, false))
    {:ok, pid} = start_supervised({ProcessOrderBook, @product})

    {:ok, %{pid: pid}}
  end

  test "can insert new price points into the order book", %{pid: pid} do
    data = %{
      "E" => 1_569_054_255_636,
      "s" => @venue_symbol,
      "b" => [["100", "15"]],
      "a" => [["101", "11"]]
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
      "E" => 1_569_054_255_636,
      "s" => @venue_symbol,
      "b" => [["100", "15"]],
      "a" => [["101", "11"]]
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
      "E" => 1_569_054_255_636,
      "s" => @venue_symbol,
      "b" => [["100", "0"]],
      "a" => [["101", "0"]]
    }

    GenServer.cast(pid, {:update, data, Timex.now()})

    assert_receive {:"$gen_cast", {:order_book_apply, forwarded_order_book, change_set}}

    assert Enum.count(forwarded_order_book.bids) == 0
    assert Enum.count(forwarded_order_book.asks) == 0

    assert %DateTime{} = forwarded_order_book.last_venue_timestamp
    assert %DateTime{} = forwarded_order_book.last_received_at
  end
end
