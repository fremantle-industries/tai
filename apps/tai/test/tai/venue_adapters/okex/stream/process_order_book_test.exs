defmodule Tai.VenueAdapters.OkEx.Stream.ProcessOrderBookTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.OkEx.Stream.ProcessOrderBook
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
    start_supervised!({Tai.PubSub, 1})
    start_supervised!({Tai.Events, 1})
    start_supervised!(OrderBook.child_spec(@product, false))
    {:ok, pid} = start_supervised({ProcessOrderBook, @product})
    Process.register(self(), @process_quote_name)

    {:ok, %{pid: pid}}
  end

  describe "snapshot" do
    test "can snapshot the order book without liquidations", %{pid: pid} do
      data = %{
        "timestamp" => "2019-01-05T02:03:06.309Z",
        "bids" => [["100", "10", "1"]],
        "asks" => [["101", "5", "1"]]
      }

      GenServer.cast(pid, {:snapshot, data, Timex.now()})

      assert_receive {:"$gen_cast", {:order_book_snapshot, forwarded_order_book, change_set}}

      assert Enum.count(forwarded_order_book.bids) == 1
      assert forwarded_order_book.bids == %{100.0 => 10.0}
      assert Enum.count(forwarded_order_book.asks) == 1
      assert forwarded_order_book.asks == %{101.0 => 5.0}
    end

    test "can snapshot the order book with liquidations", %{pid: pid} do
      data = %{
        "timestamp" => "2019-01-05T02:03:06.309Z",
        "bids" => [["100", "10", "2", "1"]],
        "asks" => [["101", "5", "2", "1"]]
      }

      GenServer.cast(pid, {:snapshot, data, Timex.now()})

      assert_receive {:"$gen_cast", {:order_book_snapshot, forwarded_order_book, change_set}}

      assert Enum.count(forwarded_order_book.bids) == 1
      assert forwarded_order_book.bids == %{100.0 => 10.0}
      assert Enum.count(forwarded_order_book.asks) == 1
      assert forwarded_order_book.asks == %{101.0 => 5.0}
    end
  end

  describe "insert" do
    test "can insert the order book without liquidations", %{pid: pid} do
      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "110", "1"]],
        "asks" => [["111", "50", "1"]]
      }

      GenServer.cast(pid, {:update, data, Timex.now()})

      assert_receive {:"$gen_cast", {:order_book_apply, forwarded_order_book, change_set}}

      assert Enum.count(forwarded_order_book.bids) == 1
      assert forwarded_order_book.bids == %{100.0 => 110.0}
      assert Enum.count(forwarded_order_book.asks) == 1
      assert forwarded_order_book.asks == %{111.0 => 50.0}
    end

    test "can insert the order book with liquidations", %{pid: pid} do
      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "110", "2", "1"]],
        "asks" => [["111", "50", "2", "1"]]
      }

      GenServer.cast(pid, {:update, data, Timex.now()})

      assert_receive {:"$gen_cast", {:order_book_apply, forwarded_order_book, change_set}}

      assert Enum.count(forwarded_order_book.bids) == 1
      assert forwarded_order_book.bids == %{100.0 => 110.0}
      assert Enum.count(forwarded_order_book.asks) == 1
      assert forwarded_order_book.asks == %{111.0 => 50.0}
    end
  end

  describe "update" do
    test "can update the order book without liquidations", %{pid: pid} do
      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "10", "1"]],
        "asks" => [["101", "5", "1"]]
      }

      GenServer.cast(pid, {:snapshot, data, Timex.now()})

      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "110", "1"]],
        "asks" => [["101", "50", "1"]]
      }

      GenServer.cast(pid, {:update, data, Timex.now()})

      assert_receive {:"$gen_cast", {:order_book_apply, forwarded_order_book, change_set}}

      assert Enum.count(forwarded_order_book.bids) == 1
      assert forwarded_order_book.bids == %{100.0 => 110.0}
      assert Enum.count(forwarded_order_book.asks) == 1
      assert forwarded_order_book.asks == %{101.0 => 50.0}
    end

    test "can update the order book with liquidations", %{pid: pid} do
      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "10", "1"]],
        "asks" => [["101", "5", "1"]]
      }

      GenServer.cast(pid, {:snapshot, data, Timex.now()})

      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "110", "2", "1"]],
        "asks" => [["101", "50", "2", "1"]]
      }

      GenServer.cast(pid, {:update, data, Timex.now()})

      assert_receive {:"$gen_cast", {:order_book_apply, forwarded_order_book, change_set}}

      assert Enum.count(forwarded_order_book.bids) == 1
      assert forwarded_order_book.bids == %{100.0 => 110.0}
      assert Enum.count(forwarded_order_book.asks) == 1
      assert forwarded_order_book.asks == %{101.0 => 50.0}
    end
  end

  describe "delete" do
    test "can delete existing price points from the order book without liquidations", %{pid: pid} do
      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "10", "1"]],
        "asks" => [["101", "5", "1"]]
      }

      GenServer.cast(pid, {:snapshot, data, Timex.now()})

      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "0", "1"]],
        "asks" => [["101", "0", "1"]]
      }

      GenServer.cast(pid, {:update, data, Timex.now()})

      assert_receive {:"$gen_cast", {:order_book_apply, forwarded_order_book, change_set}}

      assert Enum.count(forwarded_order_book.bids) == 0
      assert Enum.count(forwarded_order_book.asks) == 0
    end

    test "can delete existing price points from the order book with liquidations", %{pid: pid} do
      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "10", "1"]],
        "asks" => [["101", "5", "1"]]
      }

      GenServer.cast(pid, {:snapshot, data, Timex.now()})

      data = %{
        "timestamp" => "2019-01-05T02:03:07.456Z",
        "bids" => [["100", "0", "1", "1"]],
        "asks" => [["101", "0", "1", "1"]]
      }

      GenServer.cast(pid, {:update, data, Timex.now()})

      assert_receive {:"$gen_cast", {:order_book_apply, forwarded_order_book, change_set}}

      assert Enum.count(forwarded_order_book.bids) == 0
      assert Enum.count(forwarded_order_book.asks) == 0
    end
  end
end
