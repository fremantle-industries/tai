defmodule Tai.AdvisorTest do
  use ExUnit.Case
  doctest Tai.Advisor

  alias Tai.{Advisor, Markets.OrderBook, PubSub}

  defmodule MyAdvisor do
    use Advisor

    def handle_order_book_changes(feed_id, symbol, changes, state) do
      send :test, {feed_id, symbol, changes, state}
    end

    def handle_inside_quote(feed_id, symbol, bid, ask, changes, state) do
      send :test, {feed_id, symbol, bid, ask, changes, state}
    end
  end

  defp broadcast_order_book_changes(feed_id, symbol, changes) do
    PubSub.broadcast({:order_book_changes, feed_id}, {:order_book_changes, feed_id, symbol, changes})
  end

  setup do
    Process.register self(), :test
    book_pid = start_supervised!({OrderBook, feed_id: :my_order_book_feed, symbol: :btcusd})
    start_supervised!({
      MyAdvisor,
      [advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]]
    })

    {:ok, %{book_pid: book_pid}}
  end

  test "handle_order_book_changes is called when it receives an :order_book broadcast message" do
   broadcast_order_book_changes(:my_order_book_feed, :btcusd, [[side: :bid, price: 101.1, size: 1.1]])

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      [[side: :bid, price: 101.1, size: 1.1]],
      %{advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]}
    }
  end

  test(
    "handle_inside_quote is called when the highest bid price and size is in the change list",
    %{book_pid: book_pid}
  ) do
    book_pid |> OrderBook.replace(bids: [{101.2, 1.0}], asks: [])
    broadcast_order_book_changes(:my_order_book_feed, :btcusd, [[side: :bid, price: 101.1, size: 1.0]])

    refute_receive {
      _feed_id,
      _symbol,
      _bid,
      _ask,
      _changes,
      %{advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]}
    }

    book_pid |> OrderBook.replace(bids: [{101.1, 1.0}], asks: [])
    broadcast_order_book_changes(:my_order_book_feed, :btcusd, [[side: :bid, price: 101.1, size: 1.0]])

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      [price: 101.1, size: 1.0],
      nil,
      [[side: :bid, price: 101.1, size: 1.0]],
      %{advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]}
    }
  end

  test(
    "handle_inside_quote is called when the lowest ask price and size is in the change list",
    %{book_pid: book_pid}
  ) do
    book_pid |> OrderBook.replace(bids: [], asks: [{101.2, 1.0}])
    broadcast_order_book_changes(:my_order_book_feed, :btcusd, [[side: :ask, price: 101.1, size: 1.0]])

    refute_receive {
      _feed_id,
      _symbol,
      _bid,
      _ask,
      _changes,
      %{advisor_id: :my_advisor}
    }

    book_pid |> OrderBook.replace(bids: [], asks: [{101.1, 1.0}])
    broadcast_order_book_changes(:my_order_book_feed, :btcusd, [[side: :ask, price: 101.1, size: 1.0]])

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      nil,
      [price: 101.1, size: 1.0],
      [[side: :ask, price: 101.1, size: 1.0]],
      %{advisor_id: :my_advisor},
    }
  end

  test(
    "handle_inside_quote is called when the lowest ask price and size OR highest bid price and size is in the change list",
    %{book_pid: book_pid}
  ) do
    book_pid |> OrderBook.replace(bids: [{101.1, 0.1}], asks: [{101.2, 1.0}])
    broadcast_order_book_changes(:my_order_book_feed, :btcusd, [[side: :ask, price: 101.2, size: 1.0]])

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      [price: 101.1, size: 0.1],
      [price: 101.2, size: 1.0],
      [[side: :ask, price: 101.2, size: 1.0]],
      %{advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]}
    }
  end

  test(
    "handle_inside_quote is called when the lowest ask is now above the deleted ask in the change list",
    %{book_pid: book_pid}
  ) do
    book_pid |> OrderBook.replace(bids: [], asks: [{101.3, 1.0}])
    broadcast_order_book_changes(:my_order_book_feed, :btcusd, [[side: :ask, price: 101.2, size: 0]])

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      nil,
      [price: 101.3, size: 1.0],
      [[side: :ask, price: 101.2, size: 0]],
      %{advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]}
    }
  end

  test(
    "handle_inside_quote is called when the highest bid is now below the deleted bid in the change list",
    %{book_pid: book_pid}
  ) do
    book_pid |> OrderBook.replace(bids: [{101.2, 1.0}], asks: [])
    broadcast_order_book_changes(:my_order_book_feed, :btcusd, [[side: :bid, price: 101.3, size: 0]])

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      [price: 101.2, size: 1.0],
      nil,
      [[side: :bid, price: 101.3, size: 0]],
      %{advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]}
    }
  end
end
