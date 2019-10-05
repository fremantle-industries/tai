defmodule Tai.Markets.OrderBookTest do
  use ExUnit.Case, async: true
  alias Tai.Markets.OrderBook

  @venue __MODULE__
  @symbol :btc_usd
  @process_quote_name Tai.Markets.ProcessQuote.to_name(@venue, @symbol)
  @product struct(Tai.Venues.Product, venue_id: @venue, symbol: @symbol)

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    book_pid = start_supervised!({OrderBook, @product})

    %{book_pid: book_pid}
  end

  test ".replace/1 replaces price points and timestamps" do
    Process.register(self(), @process_quote_name)
    last_venue_timestamp = Timex.now()
    last_received_at = Timex.now()

    change_set = %OrderBook.ChangeSet{
      venue: @venue,
      symbol: @symbol,
      last_venue_timestamp: last_venue_timestamp,
      last_received_at: last_received_at,
      changes: [
        {:upsert, :bid, 999.9, 1.1},
        {:upsert, :bid, 999.8, 1.0},
        {:upsert, :ask, 1000.0, 0.1},
        {:upsert, :ask, 1001.1, 0.11}
      ]
    }

    change_set |> OrderBook.replace()

    assert_receive {:"$gen_cast",
                    {:order_book_snapshot, forwarded_order_book, applied_change_set}}

    assert applied_change_set == change_set

    assert forwarded_order_book.last_venue_timestamp == last_venue_timestamp
    assert forwarded_order_book.last_received_at == last_received_at

    assert Enum.count(forwarded_order_book.bids) == 2
    assert forwarded_order_book.bids == %{999.9 => 1.1, 999.8 => 1.0}
    assert Enum.count(forwarded_order_book.asks) == 2
    assert forwarded_order_book.asks == %{1000.0 => 0.1, 1001.1 => 0.11}
  end

  describe ".apply" do
    test "can upsert new and existing bids/asks" do
      process_quote_name = Tai.Markets.ProcessQuote.to_name(@venue, @symbol)
      Process.register(self(), process_quote_name)

      changes_1 = [
        {:upsert, :bid, 100.0, 1.0},
        {:upsert, :ask, 102.0, 11.0}
      ]

      change_set_1 = %OrderBook.ChangeSet{
        venue: @venue,
        symbol: @symbol,
        changes: changes_1,
        last_venue_timestamp: Timex.now(),
        last_received_at: Timex.now()
      }

      OrderBook.apply(change_set_1)

      assert_receive {:"$gen_cast", {:order_book_apply, _, _}}

      last_venue_timestamp = Timex.now()
      last_received_at = Timex.now()

      changes_2 = [
        {:upsert, :bid, 100.0, 5.0},
        {:upsert, :ask, 102.0, 7.0}
      ]

      change_set_2 = %OrderBook.ChangeSet{
        venue: @venue,
        symbol: @symbol,
        changes: changes_2,
        last_venue_timestamp: last_venue_timestamp,
        last_received_at: last_received_at
      }

      OrderBook.apply(change_set_2)

      assert_receive {:"$gen_cast", {:order_book_apply, forwarded_book, forwarded_change_set}}

      assert forwarded_book.last_received_at == last_received_at
      assert forwarded_book.last_venue_timestamp == last_venue_timestamp
      assert forwarded_book.bids == %{100.0 => 5.0}
      assert forwarded_book.asks == %{102.0 => 7.0}

      assert forwarded_change_set == change_set_2
    end

    test "can delete existing bids & asks" do
      process_quote_name = Tai.Markets.ProcessQuote.to_name(@venue, @symbol)
      Process.register(self(), process_quote_name)

      changes_1 = [
        {:upsert, :bid, 100.0, 1.0},
        {:upsert, :ask, 102.0, 11.0}
      ]

      change_set_1 = %OrderBook.ChangeSet{
        venue: @venue,
        symbol: @symbol,
        changes: changes_1,
        last_venue_timestamp: Timex.now(),
        last_received_at: Timex.now()
      }

      OrderBook.apply(change_set_1)

      assert_receive {:"$gen_cast", {:order_book_apply, _, _}}

      last_venue_timestamp = Timex.now()
      last_received_at = Timex.now()

      changes_2 = [
        {:delete, :bid, 100.0},
        {:delete, :ask, 102.0}
      ]

      change_set_2 = %OrderBook.ChangeSet{
        venue: @venue,
        symbol: @symbol,
        changes: changes_2,
        last_venue_timestamp: last_venue_timestamp,
        last_received_at: last_received_at
      }

      OrderBook.apply(change_set_2)

      assert_receive {:"$gen_cast", {:order_book_apply, forwarded_book, forwarded_change_set}}

      assert forwarded_book.last_received_at == last_received_at
      assert forwarded_book.last_venue_timestamp == last_venue_timestamp
      assert forwarded_book.bids == %{}
      assert forwarded_book.asks == %{}

      assert forwarded_change_set == change_set_2
    end
  end
end
