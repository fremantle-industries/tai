defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessOrderBookTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessOrderBook
  alias Tai.Markets.OrderBook

  @venue :venue_a
  @symbol :xbtusd
  @venue_symbol "XBTUSD"
  @process_quote_name Tai.Markets.ProcessQuote.to_name(@venue, @symbol)
  @last_received_at Timex.now()
  @product struct(Tai.Venues.Product,
             venue_id: @venue,
             symbol: @symbol,
             venue_symbol: @venue_symbol
           )

  setup do
    start_supervised!({Tai.PubSub, 1})
    start_supervised!(OrderBook.child_spec(@product, false))
    {:ok, pid} = start_supervised({ProcessOrderBook, @product})
    Process.register(self(), @process_quote_name)

    {:ok, %{pid: pid}}
  end

  test "can snapshot the order book", %{pid: pid} do
    data = [
      %{"id" => "a", "price" => 101, "side" => "Sell", "size" => 10},
      %{"id" => "b", "price" => 100, "side" => "Buy", "size" => 5}
    ]

    GenServer.cast(pid, {:snapshot, data, @last_received_at})

    assert_receive {:"$gen_cast", {:order_book_snapshot, forwarded_order_book, change_set}}

    assert Enum.count(forwarded_order_book.bids) == 1
    assert forwarded_order_book.bids == %{100 => 5}
    assert Enum.count(forwarded_order_book.asks) == 1
    assert forwarded_order_book.asks == %{101 => 10}
    assert forwarded_order_book.last_received_at == @last_received_at
  end

  test "can insert price points into the order book", %{pid: pid} do
    data = [
      %{"id" => "a", "price" => 101, "side" => "Sell", "size" => 10},
      %{"id" => "b", "price" => 100, "side" => "Buy", "size" => 5}
    ]

    GenServer.cast(pid, {:insert, data, @last_received_at})

    assert_receive {:"$gen_cast", {:order_book_apply, forwarded_order_book, change_set}}

    assert Enum.count(change_set.changes) == 2

    assert Enum.at(change_set.changes, 0) == {:upsert, :ask, 101, 10}
    assert Enum.at(change_set.changes, 1) == {:upsert, :bid, 100, 5}

    assert Enum.count(forwarded_order_book.bids) == 1
    assert forwarded_order_book.bids == %{100 => 5}
    assert Enum.count(forwarded_order_book.asks) == 1
    assert forwarded_order_book.asks == %{101 => 10}
    assert forwarded_order_book.last_received_at == @last_received_at
  end

  test "can update existing price points in the order book", %{pid: pid} do
    data = [
      %{"id" => "a", "price" => 101, "side" => "Sell", "size" => 10},
      %{"id" => "b", "price" => 100, "side" => "Buy", "size" => 5}
    ]

    GenServer.cast(pid, {:snapshot, data, Timex.now()})

    data = [
      %{"id" => "a", "side" => "Sell", "size" => 11},
      %{"id" => "b", "side" => "Buy", "size" => 15}
    ]

    GenServer.cast(pid, {:update, data, @last_received_at})

    assert_receive {:"$gen_cast", {:order_book_apply, forwarded_order_book, change_set}}

    assert Enum.count(change_set.changes) == 2

    assert Enum.at(change_set.changes, 0) == {:upsert, :ask, 101, 11}
    assert Enum.at(change_set.changes, 1) == {:upsert, :bid, 100, 15}

    assert Enum.count(forwarded_order_book.bids) == 1
    assert forwarded_order_book.bids == %{100 => 15}
    assert Enum.count(forwarded_order_book.asks) == 1
    assert forwarded_order_book.asks == %{101 => 11}
    assert forwarded_order_book.last_received_at == @last_received_at
  end

  test "can delete existing price points from the order book", %{pid: pid} do
    data = [
      %{"id" => "a", "price" => 101, "side" => "Sell", "size" => 10},
      %{"id" => "b", "price" => 100, "side" => "Buy", "size" => 5}
    ]

    GenServer.cast(pid, {:snapshot, data, Timex.now()})

    data = [
      %{"id" => "a", "side" => "Sell"},
      %{"id" => "b", "side" => "Buy"}
    ]

    GenServer.cast(pid, {:delete, data, @last_received_at})

    assert_receive {:"$gen_cast", {:order_book_apply, forwarded_order_book, change_set}}

    assert Enum.count(change_set.changes) == 2

    assert Enum.at(change_set.changes, 0) == {:delete, :ask, 101}
    assert Enum.at(change_set.changes, 1) == {:delete, :bid, 100}

    assert Enum.count(forwarded_order_book.bids) == 0
    assert Enum.count(forwarded_order_book.asks) == 0
    assert forwarded_order_book.last_received_at == @last_received_at
  end
end
