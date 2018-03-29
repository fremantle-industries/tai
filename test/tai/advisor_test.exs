defmodule Tai.AdvisorTest do
  use ExUnit.Case
  doctest Tai.Advisor

  alias Tai.{Advisor, PubSub}
  alias Tai.Markets.{OrderBook, PriceLevel}
  alias Tai.Trading.{Order, Orders, OrderResponses, OrderStatus, OrderTypes}

  defmodule MyOrderBookFeed do
    use Tai.Exchanges.OrderBookFeed

    def subscribe_to_order_books(_pid, _feed_id, _symbols), do: :ok
    def handle_msg(_msg, _feed_id), do: :ok
  end

  defmodule MyAdvisor do
    use Advisor

    def handle_order_book_changes(feed_id, symbol, changes, state) do
      send :test, {feed_id, symbol, changes, state}
    end

    def handle_inside_quote(feed_id, symbol, bid, ask, changes, state) do
      send :test, {feed_id, symbol, bid, ask, changes, state}

      {:ok, %{store: %{hello: "world"}}}
    end
  end

  setup do
    Process.register self(), :test
    book_pid = start_supervised!({OrderBook, feed_id: :my_order_book_feed, symbol: :btcusd})
    start_supervised!({Tai.ExchangeAdapters.Test.Account, :my_test_exchange})

    on_exit fn ->
      Orders.clear()
    end

    {:ok, %{book_pid: book_pid}}
  end

  test(
    "handle_order_book_changes is called when it receives a broadcast message",
    %{book_pid: book_pid}
  ) do
    start_supervised!({
      MyAdvisor,
      [
        advisor_id: :my_advisor,
        order_books: %{my_order_book_feed: [:btcusd]}
      ]
    })
    changes = %OrderBook{bids: %{101.2 => {1.1, nil, nil}}, asks: %{}}
    book_pid |> OrderBook.update(changes)
    MyOrderBookFeed.broadcast_order_book_changes(:ok, :my_order_book_feed, :btcusd, changes)

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      ^changes,
      %Advisor{}
    }
  end

  test(
    "handle_inside_quote is called after the snapshot broadcast message",
    %{book_pid: book_pid}
  ) do
    start_supervised!({
      MyAdvisor,
      [
        advisor_id: :my_advisor,
        order_books: %{my_order_book_feed: [:btcusd]}
      ]
    })
    snapshot = %OrderBook{
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }
    book_pid |> OrderBook.replace(snapshot)
    MyOrderBookFeed.broadcast_order_book_snapshot(:ok, :my_order_book_feed, :btcusd, snapshot)

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      %PriceLevel{price: 101.2, size: 1.0, processed_at: nil, server_changed_at: nil},
      %PriceLevel{price: 101.3, size: 0.1, processed_at: nil, server_changed_at: nil},
      ^snapshot,
      %Advisor{}
    }
  end

  test(
    "handle_inside_quote is called on broadcast changes when the inside bid price is >= to the previous bid or != size ",
    %{book_pid: book_pid}
  ) do
    start_supervised!({
      MyAdvisor,
      [
        advisor_id: :my_advisor,
        order_books: %{my_order_book_feed: [:btcusd]}
      ]
    })
    snapshot = %OrderBook{
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }
    book_pid |> OrderBook.replace(snapshot)
    MyOrderBookFeed.broadcast_order_book_snapshot(:ok, :my_order_book_feed, :btcusd, snapshot)

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      %PriceLevel{price: 101.2, size: 1.0, processed_at: nil, server_changed_at: nil},
      %PriceLevel{price: 101.3, size: 0.1, processed_at: nil, server_changed_at: nil},
      ^snapshot,
      %Advisor{}
    }

    changes = %OrderBook{bids: %{101.2 => {1.1, nil, nil}}, asks: %{}}
    MyOrderBookFeed.broadcast_order_book_changes(:ok, :my_order_book_feed, :btcusd, changes)

    refute_receive {
      _feed_id,
      _symbol,
      _bid,
      _ask,
      _changes,
      %Advisor{}
    }

    book_pid |> OrderBook.update(changes)
    MyOrderBookFeed.broadcast_order_book_changes(:ok, :my_order_book_feed, :btcusd, changes)

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      %PriceLevel{price: 101.2, size: 1.1, processed_at: nil, server_changed_at: nil},
      %PriceLevel{price: 101.3, size: 0.1, processed_at: nil, server_changed_at: nil},
      ^changes,
      %Advisor{}
    }
  end

  test(
    "handle_inside_quote is called on broadcast changes when the inside ask price is <= to the previous ask or != size ",
    %{book_pid: book_pid}
  ) do
    start_supervised!({
      MyAdvisor,
      [
        advisor_id: :my_advisor,
        order_books: %{my_order_book_feed: [:btcusd]}
      ]
    })
    snapshot = %OrderBook{
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }
    book_pid |> OrderBook.replace(snapshot)
    MyOrderBookFeed.broadcast_order_book_snapshot(:ok, :my_order_book_feed, :btcusd, snapshot)

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      %PriceLevel{price: 101.2, size: 1.0, processed_at: nil, server_changed_at: nil},
      %PriceLevel{price: 101.3, size: 0.1, processed_at: nil, server_changed_at: nil},
      ^snapshot,
      %Advisor{}
    }

    changes = %OrderBook{bids: %{}, asks: %{101.3 => {0.2, nil, nil}}}
    MyOrderBookFeed.broadcast_order_book_changes(:ok, :my_order_book_feed, :btcusd, changes)

    refute_receive {
      _feed_id,
      _symbol,
      _bid,
      _ask,
      _changes,
      %Advisor{}
    }

    book_pid |> OrderBook.update(changes)
    MyOrderBookFeed.broadcast_order_book_changes(:ok, :my_order_book_feed, :btcusd, changes)

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      %PriceLevel{price: 101.2, size: 1.0, processed_at: nil, server_changed_at: nil},
      %PriceLevel{price: 101.3, size: 0.2, processed_at: nil, server_changed_at: nil},
      ^changes,
      %Advisor{}
    }
  end

  test "handle_inside_quote can store data in the state", %{book_pid: book_pid} do
    start_supervised!({
      MyAdvisor,
      [
        advisor_id: :my_advisor,
        order_books: %{my_order_book_feed: [:btcusd]}
      ]
    })
    snapshot = %OrderBook{
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }
    book_pid |> OrderBook.replace(snapshot)
    MyOrderBookFeed.broadcast_order_book_snapshot(:ok, :my_order_book_feed, :btcusd, snapshot)

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      %PriceLevel{price: 101.2, size: 1.0, processed_at: nil, server_changed_at: nil},
      %PriceLevel{price: 101.3, size: 0.1, processed_at: nil, server_changed_at: nil},
      ^snapshot,
      %Advisor{}
    }

    changes = %OrderBook{bids: %{}, asks: %{101.3 => {0.2, nil, nil}}}
    book_pid |> OrderBook.update(changes)
    MyOrderBookFeed.broadcast_order_book_changes(:ok, :my_order_book_feed, :btcusd, changes)

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      %PriceLevel{price: 101.2, size: 1.0, processed_at: nil, server_changed_at: nil},
      %PriceLevel{price: 101.3, size: 0.2, processed_at: nil, server_changed_at: nil},
      ^changes,
      %Advisor{advisor_id: :my_advisor, store: %{hello: "world"}}
    }
  end

  test "handle_inside_quote can create multiple buy_limit orders", %{book_pid: book_pid} do
    defmodule MyBuyLimitAdvisor do
      use Advisor

      def handle_inside_quote(_feed_id, _symbol, _bid, _ask, _changes, _state) do
        limit_orders = [
          {:my_test_exchange, :btcusd_success, 101.1, 0.1},
          {:my_test_exchange, :btcusd_success, 10.1, 0.11},
          {:my_test_exchange, :btcusd_insufficient_funds, 1.1, 0.1}
        ]

        {:ok, %{limit_orders: limit_orders}}
      end

      def handle_order_enqueued(order, state) do
        send :test, {order, state}
      end

      def handle_order_create_ok(order, state) do
        send :test, {order, state}
      end

      def handle_order_create_error(reason, order, state) do
        send :test, {reason, order, state}
      end
    end

    start_supervised!({
      MyBuyLimitAdvisor,
      [
        advisor_id: :my_buy_limit_advisor,
        order_books: %{my_order_book_feed: [:btcusd]}
      ]
    })

    snapshot = %OrderBook{
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }
    book_pid |> OrderBook.replace(snapshot)
    MyOrderBookFeed.broadcast_order_book_snapshot(:ok, :my_order_book_feed, :btcusd, snapshot)

    assert_receive {enqueued_order_1, %Advisor{}}
    assert_receive {enqueued_order_2, %Advisor{}}
    assert_receive {enqueued_order_3, %Advisor{}}

    assert enqueued_order_1.server_id == nil
    assert enqueued_order_1.exchange == :my_test_exchange
    assert enqueued_order_1.symbol == :btcusd_success
    assert enqueued_order_1.type == OrderTypes.buy_limit
    assert enqueued_order_1.price == 101.1
    assert enqueued_order_1.size == 0.1
    assert enqueued_order_1.status == OrderStatus.enqueued

    assert enqueued_order_2.server_id == nil
    assert enqueued_order_2.exchange == :my_test_exchange
    assert enqueued_order_2.symbol == :btcusd_success
    assert enqueued_order_2.type == OrderTypes.buy_limit
    assert enqueued_order_2.price == 10.1
    assert enqueued_order_2.size == 0.11
    assert enqueued_order_2.status == OrderStatus.enqueued

    assert enqueued_order_3.server_id == nil
    assert enqueued_order_3.exchange == :my_test_exchange
    assert enqueued_order_3.symbol == :btcusd_insufficient_funds
    assert enqueued_order_3.type == OrderTypes.buy_limit
    assert enqueued_order_3.price == 1.1
    assert enqueued_order_3.size == 0.1
    assert enqueued_order_3.status == OrderStatus.enqueued

    assert_receive {created_order_a, %Advisor{}}
    assert_receive {created_order_b, %Advisor{}}
    assert_receive {%OrderResponses.InsufficientFunds{}, error_order, %Advisor{}}

    [created_order_1, created_order_2] = [created_order_a, created_order_b]
                                         |> Enum.sort(
                                           &(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt)
                                         )

    assert created_order_1.server_id != nil
    assert created_order_1.exchange == :my_test_exchange
    assert created_order_1.symbol == :btcusd_success
    assert created_order_1.type == OrderTypes.buy_limit
    assert created_order_1.price == 101.1
    assert created_order_1.size == 0.1
    assert created_order_1.status == OrderStatus.pending

    assert created_order_2.server_id != nil
    assert created_order_2.exchange == :my_test_exchange
    assert created_order_2.symbol == :btcusd_success
    assert created_order_2.type == OrderTypes.buy_limit
    assert created_order_2.price == 10.1
    assert created_order_2.size == 0.11
    assert created_order_2.status == OrderStatus.pending

    assert error_order.server_id == nil
    assert error_order.exchange == :my_test_exchange
    assert error_order.symbol == :btcusd_insufficient_funds
    assert error_order.type == OrderTypes.buy_limit
    assert error_order.price == 1.1
    assert error_order.size == 0.1
    assert error_order.status == OrderStatus.error
  end

  test "handle_inside_quote can create multiple sell_limit orders", %{book_pid: book_pid} do
    defmodule MySellLimitAdvisor do
      use Advisor

      def handle_inside_quote(_feed_id, _symbol, _bid, _ask, _changes, _state) do
        limit_orders = [
          {:my_test_exchange, :btcusd_success, 101.1, -0.1},
          {:my_test_exchange, :btcusd_success, 10.1, -0.11},
          {:my_test_exchange, :btcusd_insufficient_funds, 1.1, -0.1}
        ]

        {:ok, %{limit_orders: limit_orders}}
      end

      def handle_order_enqueued(order, state) do
        send :test, {order, state}
      end

      def handle_order_create_ok(order, state) do
        send :test, {order, state}
      end

      def handle_order_create_error(reason, order, state) do
        send :test, {reason, order, state}
      end
    end

    start_supervised!({
      MySellLimitAdvisor,
      [
        advisor_id: :my_sell_limit_advisor,
        order_books: %{my_order_book_feed: [:btcusd]}
      ]
    })

    snapshot = %OrderBook{
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }
    book_pid |> OrderBook.replace(snapshot)
    MyOrderBookFeed.broadcast_order_book_snapshot(:ok, :my_order_book_feed, :btcusd, snapshot)

    assert_receive {enqueued_order_1, %Advisor{}}
    assert_receive {enqueued_order_2, %Advisor{}}
    assert_receive {enqueued_order_3, %Advisor{}}

    assert enqueued_order_1.server_id == nil
    assert enqueued_order_1.exchange == :my_test_exchange
    assert enqueued_order_1.symbol == :btcusd_success
    assert enqueued_order_1.type == OrderTypes.sell_limit
    assert enqueued_order_1.price == 101.1
    assert enqueued_order_1.size == 0.1
    assert enqueued_order_1.status == OrderStatus.enqueued

    assert enqueued_order_2.server_id == nil
    assert enqueued_order_2.exchange == :my_test_exchange
    assert enqueued_order_2.symbol == :btcusd_success
    assert enqueued_order_2.type == OrderTypes.sell_limit
    assert enqueued_order_2.price == 10.1
    assert enqueued_order_2.size == 0.11
    assert enqueued_order_2.status == OrderStatus.enqueued

    assert enqueued_order_3.server_id == nil
    assert enqueued_order_3.exchange == :my_test_exchange
    assert enqueued_order_3.symbol == :btcusd_insufficient_funds
    assert enqueued_order_3.type == OrderTypes.sell_limit
    assert enqueued_order_3.price == 1.1
    assert enqueued_order_3.size == 0.1
    assert enqueued_order_3.status == OrderStatus.enqueued

    assert_receive {created_order_a, %Advisor{}}
    assert_receive {created_order_b, %Advisor{}}
    assert_receive {%OrderResponses.InsufficientFunds{}, error_order, %Advisor{}}

    [created_order_1, created_order_2] = [created_order_a, created_order_b]
                                         |> Enum.sort(
                                           &(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt)
                                         )

    assert created_order_1.server_id != nil
    assert created_order_1.exchange == :my_test_exchange
    assert created_order_1.symbol == :btcusd_success
    assert created_order_1.type == OrderTypes.sell_limit
    assert created_order_1.price == 101.1
    assert created_order_1.size == 0.1
    assert created_order_1.status == OrderStatus.pending

    assert created_order_2.server_id != nil
    assert created_order_2.exchange == :my_test_exchange
    assert created_order_2.symbol == :btcusd_success
    assert created_order_2.type == OrderTypes.sell_limit
    assert created_order_2.price == 10.1
    assert created_order_2.size == 0.11
    assert created_order_2.status == OrderStatus.pending

    assert error_order.server_id == nil
    assert error_order.exchange == :my_test_exchange
    assert error_order.symbol == :btcusd_insufficient_funds
    assert error_order.type == OrderTypes.sell_limit
    assert error_order.price == 1.1
    assert error_order.size == 0.1
    assert error_order.status == OrderStatus.error
  end

  test "handle_inside_quote can cancel orders", %{book_pid: book_pid} do
    defmodule MyCancelOrdersAdvisor do
      use Advisor

      alias Tai.Trading.OrderStatus

      def handle_inside_quote(_feed_id, _symbol, _bid, _ask, _changes, _state) do
        cond do
          Orders.count() == 0 ->
            limit_orders = [
              {:my_test_exchange, :btcusd_success, 101.1, 0.1},
              {:my_test_exchange, :btcusd_success, 10.1, 0.11}
            ]
            {:ok, %{limit_orders: limit_orders}}
          (pending_orders = Orders.where(status: OrderStatus.pending)) |> Enum.count == 2 ->
            cancel_orders = pending_orders |> Enum.map(& &1.client_id)
            {:ok, %{cancel_orders: cancel_orders}}
          true ->
            :ok
        end
      end

      def handle_order_enqueued(order, state) do
        send :test, {order, state}
      end

      def handle_order_create_ok(order, state) do
        send :test, {order, state}
      end

      def handle_order_create_error(reason, order, state) do
        send :test, {reason, order, state}
      end

      def handle_order_cancelling(order, state) do
        send :test, {order, state}
      end

      def handle_order_cancelled(order, state) do
        send :test, {order, state}
      end
    end

    start_supervised!({
      MyCancelOrdersAdvisor,
      [
        advisor_id: :my_cancel_orders_advisor,
        order_books: %{my_order_book_feed: [:btcusd]}
      ]
    })

    snapshot = %OrderBook{
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }
    book_pid |> OrderBook.replace(snapshot)
    MyOrderBookFeed.broadcast_order_book_snapshot(:ok, :my_order_book_feed, :btcusd, snapshot)

    assert_receive {
      %Order{
        client_id: _,
        server_id: nil,
        exchange: :my_test_exchange,
        symbol: :btcusd_success,
        price: 101.1,
        size: 0.1,
        status: :enqueued
      },
      %Advisor{}
    }
    assert_receive {
      %Order{
        client_id: _,
        server_id: nil,
        exchange: :my_test_exchange,
        symbol: :btcusd_success,
        price: 10.1,
        size: 0.11,
        status: :enqueued
      },
      %Advisor{}
    }

    assert_receive {
      %Order{
        client_id: _,
        server_id: _,
        exchange: :my_test_exchange,
        symbol: :btcusd_success,
        price: 101.1,
        size: 0.1,
        status: :pending
      },
      %Advisor{}
    }
    assert_receive {
      %Order{
        client_id: _,
        server_id: _,
        exchange: :my_test_exchange,
        symbol: :btcusd_success,
        price: 10.1,
        size: 0.11,
        status: :pending
      },
      %Advisor{}
    }

    changes = %OrderBook{
      bids: %{101.2 => {1.1, nil, nil}},
      asks: %{}
    }
    book_pid |> OrderBook.update(changes)
    MyOrderBookFeed.broadcast_order_book_changes(:ok, :my_order_book_feed, :btcusd, changes)

    assert_receive {
      %Order{
        client_id: _,
        server_id: _,
        exchange: :my_test_exchange,
        symbol: :btcusd_success,
        price: 101.1,
        size: 0.1,
        status: :cancelling
      },
      %Advisor{}
    }
    assert_receive {
      %Order{
        client_id: _,
        server_id: _,
        exchange: :my_test_exchange,
        symbol: :btcusd_success,
        price: 10.1,
        size: 0.11,
        status: :cancelling
      },
      %Advisor{}
    }
    assert_receive {
      %Order{
        client_id: _,
        server_id: _,
        exchange: :my_test_exchange,
        symbol: :btcusd_success,
        price: 101.1,
        size: 0.1,
        status: :cancelled
      },
      %Advisor{}
    }
    assert_receive {
      %Order{
        client_id: _,
        server_id: _,
        exchange: :my_test_exchange,
        symbol: :btcusd_success,
        price: 10.1,
        size: 0.11,
        status: :cancelled
      },
      %Advisor{}
    }
  end
end
