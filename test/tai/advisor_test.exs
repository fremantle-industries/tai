defmodule Tai.AdvisorTest do
  use ExUnit.Case
  doctest Tai.Advisor

  alias Tai.{Advisor, Markets.OrderBook, PubSub}
  alias Tai.Trading.{Order, Orders, OrderResponses}

  defmodule MyAdvisor do
    use Advisor

    def handle_order_book_changes(feed_id, symbol, changes, state) do
      send :test, {feed_id, symbol, changes, state}
    end

    def handle_inside_quote(feed_id, symbol, bid, ask, snapshot_or_changes, state) do
      send :test, {feed_id, symbol, bid, ask, snapshot_or_changes, state}
      :ok
    end

    def handle_order_enqueued(_order, _state), do: nil
    def handle_order_create_ok(_order, _state), do: nil
    def handle_order_create_error(_reason, _order, _state), do: nil
    def handle_order_cancelling(_order, _state), do: nil
    def handle_order_cancelled(_order, _state), do: nil
  end

  defp broadcast_order_book_changes(feed_id, symbol, changes) do
    PubSub.broadcast(
      {:order_book_changes, feed_id},
      {:order_book_changes, feed_id, symbol, changes}
    )
  end

  defp broadcast_order_book_snapshot(feed_id, symbol, normalized_bids, normalized_asks) do
    PubSub.broadcast(
      {:order_book_snapshot, feed_id},
      {:order_book_snapshot, feed_id, symbol, normalized_bids, normalized_asks}
    )
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
      [advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]]
    })
    changes = %{bids: %{101.2 => {1.1, nil, nil}}, asks: %{}}
    book_pid |> OrderBook.update(changes)
    broadcast_order_book_changes(:my_order_book_feed, :btcusd, changes)

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      ^changes,
      %{advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]}
    }
  end

  test(
    "handle_inside_quote is called after the snapshot broadcast message",
    %{book_pid: book_pid}
  ) do
    start_supervised!({
      MyAdvisor,
      [advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]]
    })
    replacement = %{
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }
    book_pid |> OrderBook.replace(replacement)
    broadcast_order_book_snapshot(:my_order_book_feed, :btcusd, replacement.bids, replacement.asks)

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      [price: 101.2, size: 1.0, processed_at: nil, server_changed_at: nil],
      [price: 101.3, size: 0.1, processed_at: nil, server_changed_at: nil],
      ^replacement,
      %{advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]}
    }
  end

  test(
    "handle_inside_quote is called on broadcast changes when the inside bid price is >= to the previous bid or != size ",
    %{book_pid: book_pid}
  ) do
    start_supervised!({
      MyAdvisor,
      [advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]]
    })
    replacement = %{
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }
    book_pid |> OrderBook.replace(replacement)
    broadcast_order_book_snapshot(:my_order_book_feed, :btcusd, replacement.bids, replacement.asks)

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      [price: 101.2, size: 1.0, processed_at: nil, server_changed_at: nil],
      [price: 101.3, size: 0.1, processed_at: nil, server_changed_at: nil],
      ^replacement,
      %{advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]}
    }

    changes = %{bids: %{101.2 => {1.1, nil, nil}}, asks: %{}}
    broadcast_order_book_changes(:my_order_book_feed, :btcusd, changes)

    refute_receive {
      _feed_id,
      _symbol,
      _bid,
      _ask,
      _changes,
      %{advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]}
    }

    book_pid |> OrderBook.update(changes)
    broadcast_order_book_changes(:my_order_book_feed, :btcusd, changes)

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      [price: 101.2, size: 1.1, processed_at: nil, server_changed_at: nil],
      [price: 101.3, size: 0.1, processed_at: nil, server_changed_at: nil],
      ^changes,
      %{advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]}
    }
  end

  test(
    "handle_inside_quote is called on broadcast changes when the inside ask price is <= to the previous ask or != size ",
    %{book_pid: book_pid}
  ) do
    start_supervised!({
      MyAdvisor,
      [advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]]
    })
    replacement = %{
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }
    book_pid |> OrderBook.replace(replacement)
    broadcast_order_book_snapshot(:my_order_book_feed, :btcusd, replacement.bids, replacement.asks)

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      [price: 101.2, size: 1.0, processed_at: nil, server_changed_at: nil],
      [price: 101.3, size: 0.1, processed_at: nil, server_changed_at: nil],
      ^replacement,
      %{advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]}
    }

    changes = %{bids: %{}, asks: %{101.3 => {0.2, nil, nil}}}
    broadcast_order_book_changes(:my_order_book_feed, :btcusd, changes)

    refute_receive {
      _feed_id,
      _symbol,
      _bid,
      _ask,
      _changes,
      %{advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]}
    }

    book_pid |> OrderBook.update(changes)
    broadcast_order_book_changes(:my_order_book_feed, :btcusd, changes)

    assert_receive {
      :my_order_book_feed,
      :btcusd,
      [price: 101.2, size: 1.0, processed_at: nil, server_changed_at: nil],
      [price: 101.3, size: 0.2, processed_at: nil, server_changed_at: nil],
      ^changes,
      %{advisor_id: :my_advisor, order_book_feed_ids: [:my_order_book_feed]}
    }
  end

  test "handle_inside_quote can create multiple buy_limit orders", %{book_pid: book_pid} do
    defmodule MyBuyLimitAdvisor do
      use Advisor

      def handle_order_book_changes(_feed_id, _symbol, _changes, _state), do: nil

      def handle_inside_quote(_feed_id, _symbol, _bid, _ask, _snapshot_or_changes, _state) do
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

      def handle_order_cancelling(_order, _state), do: nil
      def handle_order_cancelled(_order, _state), do: nil
    end

    start_supervised!({
      MyBuyLimitAdvisor,
      [advisor_id: :my_buy_limit_advisor, order_book_feed_ids: [:my_order_book_feed]]
    })

    replacement = %{
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }
    book_pid |> OrderBook.replace(replacement)
    broadcast_order_book_snapshot(:my_order_book_feed, :btcusd, replacement.bids, replacement.asks)

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
      %{advisor_id: :my_buy_limit_advisor, order_book_feed_ids: [:my_order_book_feed], inside_quotes: _}
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
      %{advisor_id: :my_buy_limit_advisor, order_book_feed_ids: [:my_order_book_feed], inside_quotes: _}
    }
    assert_receive {
      %Order{
        client_id: _,
        server_id: nil,
        exchange: :my_test_exchange,
        symbol: :btcusd_insufficient_funds,
        price: 1.1,
        size: 0.1,
        status: :enqueued
      },
      %{advisor_id: :my_buy_limit_advisor, order_book_feed_ids: [:my_order_book_feed], inside_quotes: _}
    }

    assert_receive {
      %Order{
        client_id: _,
        server_id: server_id_1,
        exchange: :my_test_exchange,
        symbol: :btcusd_success,
        price: 101.1,
        size: 0.1,
        status: :pending
      },
      %{advisor_id: :my_buy_limit_advisor, order_book_feed_ids: [:my_order_book_feed], inside_quotes: _}
    }
    assert server_id_1 != nil
    assert_receive {
      %Order{
        client_id: _,
        server_id: server_id_2,
        exchange: :my_test_exchange,
        symbol: :btcusd_success,
        price: 10.1,
        size: 0.11,
        status: :pending
      },
      %{advisor_id: :my_buy_limit_advisor, order_book_feed_ids: [:my_order_book_feed], inside_quotes: _}
    }
    assert server_id_2 != nil
    assert_receive {
      %OrderResponses.InsufficientFunds{},
      %Order{
        client_id: _,
        server_id: nil,
        exchange: :my_test_exchange,
        symbol: :btcusd_insufficient_funds,
        price: 1.1,
        size: 0.1,
        status: :error
      },
      %{advisor_id: :my_buy_limit_advisor, order_book_feed_ids: [:my_order_book_feed], inside_quotes: _}
    }
  end

  test "handle_inside_quote can create multiple sell_limit orders", %{book_pid: book_pid} do
    defmodule MySellLimitAdvisor do
      use Advisor

      def handle_order_book_changes(_feed_id, _symbol, _changes, _state), do: nil

      def handle_inside_quote(_feed_id, _symbol, _bid, _ask, _snapshot_or_changes, _state) do
        limit_orders = [
          {:my_test_exchange, :btcusd, 101.1, -0.1},
          {:my_test_exchange, :btcusd, 10.1, -0.11}
        ]

        {:ok, %{limit_orders: limit_orders}}
      end

      def handle_order_enqueued(order, state) do
        send :test, {order, state}
      end

      def handle_order_create_ok(_order, _state), do: nil
      def handle_order_create_error(_reason, _order, _state), do: nil
      def handle_order_cancelling(_order, _state), do: nil
      def handle_order_cancelled(_order, _state), do: nil
    end

    start_supervised!({
      MySellLimitAdvisor,
      [advisor_id: :my_sell_limit_advisor, order_book_feed_ids: [:my_order_book_feed]]
    })

    replacement = %{
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }
    book_pid |> OrderBook.replace(replacement)
    broadcast_order_book_snapshot(:my_order_book_feed, :btcusd, replacement.bids, replacement.asks)

    assert_receive {
      %Order{
        client_id: _,
        server_id: nil,
        exchange: :my_test_exchange,
        symbol: :btcusd,
        price: 101.1,
        size: -0.1,
        status: :enqueued
      },
      %{advisor_id: :my_sell_limit_advisor, order_book_feed_ids: [:my_order_book_feed], inside_quotes: _}
    }
    assert_receive {
      %Order{
        client_id: _,
        server_id: nil,
        exchange: :my_test_exchange,
        symbol: :btcusd,
        price: 10.1,
        size: -0.11,
        status: :enqueued
      },
      %{advisor_id: :my_sell_limit_advisor, order_book_feed_ids: [:my_order_book_feed], inside_quotes: _}
    }
  end

  test "handle_inside_quote can cancel orders", %{book_pid: book_pid} do
    defmodule MyCancelOrdersAdvisor do
      use Advisor

      alias Tai.Trading.OrderStatus

      def handle_order_book_changes(_feed_id, _symbol, _changes, _state), do: nil

      def handle_inside_quote(_feed_id, _symbol, _bid, _ask, _snapshot_or_changes, _state) do
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
      [advisor_id: :my_cancel_orders_advisor, order_book_feed_ids: [:my_order_book_feed]]
    })

    replacement = %{
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }
    book_pid |> OrderBook.replace(replacement)
    broadcast_order_book_snapshot(:my_order_book_feed, :btcusd, replacement.bids, replacement.asks)

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
      %{advisor_id: :my_cancel_orders_advisor, order_book_feed_ids: [:my_order_book_feed], inside_quotes: _}
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
      %{advisor_id: :my_cancel_orders_advisor, order_book_feed_ids: [:my_order_book_feed], inside_quotes: _}
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
      %{advisor_id: :my_cancel_orders_advisor, order_book_feed_ids: [:my_order_book_feed], inside_quotes: _}
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
      %{advisor_id: :my_cancel_orders_advisor, order_book_feed_ids: [:my_order_book_feed], inside_quotes: _}
    }

    changes = %{
      bids: %{101.2 => {1.1, nil, nil}},
      asks: %{}
    }
    book_pid |> OrderBook.update(changes)
    broadcast_order_book_changes(:my_order_book_feed, :btcusd, changes)

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
      %{advisor_id: :my_cancel_orders_advisor, order_book_feed_ids: [:my_order_book_feed], inside_quotes: _}
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
      %{advisor_id: :my_cancel_orders_advisor, order_book_feed_ids: [:my_order_book_feed], inside_quotes: _}
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
      %{advisor_id: :my_cancel_orders_advisor, order_book_feed_ids: [:my_order_book_feed], inside_quotes: _}
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
      %{advisor_id: :my_cancel_orders_advisor, order_book_feed_ids: [:my_order_book_feed], inside_quotes: _}
    }
  end
end
