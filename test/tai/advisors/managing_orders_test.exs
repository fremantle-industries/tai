defmodule Tai.Advisors.ManagingOrdersTest do
  use ExUnit.Case

  alias Tai.{Advisor}
  alias Tai.Markets.{OrderBook}
  alias Tai.Trading.{Order, Orders, OrderResponses, OrderStatus, OrderSubmission}

  defmodule MyOrderAdvisor do
    use Advisor

    def handle_inside_quote(_feed_id, _symbol, _inside_quote, _changes, state) do
      {:ok, %{orders: state.store.orders}}
    end

    def handle_order_enqueued(order, state) do
      send(:test, {order, state})
    end

    def handle_order_create_ok(order, state) do
      send(:test, {order, state})
    end

    def handle_order_create_error(reason, order, state) do
      send(:test, {reason, order, state})
    end
  end

  defmodule MyCancelOrdersAdvisor do
    use Advisor

    alias Tai.Trading.OrderStatus

    def handle_inside_quote(_feed_id, _symbol, _inside_quote, _changes, _state) do
      cond do
        Orders.count() == 0 ->
          orders = [
            OrderSubmission.buy_limit(:my_test_account, :btcusd_success, 101.1, 0.1),
            OrderSubmission.buy_limit(:my_test_account, :btcusd_success, 10.1, 0.11)
          ]

          {:ok, %{orders: orders}}

        (pending_orders = Orders.where(status: OrderStatus.pending())) |> Enum.count() == 2 ->
          cancel_orders = pending_orders |> Enum.map(& &1.client_id)
          {:ok, %{cancel_orders: cancel_orders}}

        true ->
          :ok
      end
    end

    def handle_order_enqueued(order, state) do
      send(:test, {order, state})
    end

    def handle_order_create_ok(order, state) do
      send(:test, {order, state})
    end

    def handle_order_create_error(reason, order, state) do
      send(:test, {reason, order, state})
    end

    def handle_order_cancelling(order, state) do
      send(:test, {order, state})
    end

    def handle_order_cancelled(order, state) do
      send(:test, {order, state})
    end
  end

  setup do
    Process.register(self(), :test)
    book_pid = start_supervised!({OrderBook, feed_id: :my_order_book_feed, symbol: :btcusd})
    start_supervised!({Tai.ExchangeAdapters.Test.Account, :my_test_account})

    on_exit(fn ->
      Orders.clear()
    end)

    {:ok, %{book_pid: book_pid}}
  end

  test "handle_inside_quote can create multiple buy_limit orders", %{book_pid: book_pid} do
    start_supervised!({
      MyOrderAdvisor,
      [
        advisor_id: :my_buy_limit_advisor,
        order_books: %{my_order_book_feed: [:btcusd]},
        accounts: [:my_test_account],
        store: %{
          orders: [
            OrderSubmission.buy_limit(:my_test_account, :btcusd_success, 101.1, 0.1),
            OrderSubmission.buy_limit(:my_test_account, :btcusd_success, 10.1, 0.11),
            OrderSubmission.buy_limit(:my_test_account, :btcusd_insufficient_funds, 1.1, 0.1)
          ]
        }
      ]
    })

    snapshot = %OrderBook{
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }

    book_pid |> OrderBook.replace(snapshot)

    assert_receive {enqueued_order_1, %Advisor{}}
    assert_receive {enqueued_order_2, %Advisor{}}
    assert_receive {enqueued_order_3, %Advisor{}}

    assert enqueued_order_1.server_id == nil
    assert enqueued_order_1.account_id == :my_test_account
    assert enqueued_order_1.symbol == :btcusd_success
    assert enqueued_order_1.side == Order.buy()
    assert enqueued_order_1.type == Order.limit()
    assert enqueued_order_1.price == 101.1
    assert enqueued_order_1.size == 0.1
    assert enqueued_order_1.status == OrderStatus.enqueued()

    assert enqueued_order_2.server_id == nil
    assert enqueued_order_2.account_id == :my_test_account
    assert enqueued_order_2.symbol == :btcusd_success
    assert enqueued_order_2.side == Order.buy()
    assert enqueued_order_2.type == Order.limit()
    assert enqueued_order_2.price == 10.1
    assert enqueued_order_2.size == 0.11
    assert enqueued_order_2.status == OrderStatus.enqueued()

    assert enqueued_order_3.server_id == nil
    assert enqueued_order_3.account_id == :my_test_account
    assert enqueued_order_3.symbol == :btcusd_insufficient_funds
    assert enqueued_order_3.side == Order.buy()
    assert enqueued_order_3.type == Order.limit()
    assert enqueued_order_3.price == 1.1
    assert enqueued_order_3.size == 0.1
    assert enqueued_order_3.status == OrderStatus.enqueued()

    assert_receive {created_order_a, %Advisor{}}
    assert_receive {created_order_b, %Advisor{}}
    assert_receive {%OrderResponses.InsufficientFunds{}, error_order, %Advisor{}}

    [created_order_1, created_order_2] =
      [created_order_a, created_order_b]
      |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

    assert created_order_1.server_id != nil
    assert created_order_1.account_id == :my_test_account
    assert created_order_1.symbol == :btcusd_success
    assert created_order_1.side == Order.buy()
    assert created_order_1.type == Order.limit()
    assert created_order_1.price == 101.1
    assert created_order_1.size == 0.1
    assert created_order_1.status == OrderStatus.pending()

    assert created_order_2.server_id != nil
    assert created_order_2.account_id == :my_test_account
    assert created_order_2.symbol == :btcusd_success
    assert created_order_2.side == Order.buy()
    assert created_order_2.type == Order.limit()
    assert created_order_2.price == 10.1
    assert created_order_2.size == 0.11
    assert created_order_2.status == OrderStatus.pending()

    assert error_order.server_id == nil
    assert error_order.account_id == :my_test_account
    assert error_order.symbol == :btcusd_insufficient_funds
    assert error_order.side == Order.buy()
    assert error_order.type == Order.limit()
    assert error_order.price == 1.1
    assert error_order.size == 0.1
    assert error_order.status == OrderStatus.error()
  end

  test "handle_inside_quote can create multiple sell_limit orders", %{book_pid: book_pid} do
    start_supervised!({
      MyOrderAdvisor,
      [
        advisor_id: :my_sell_limit_advisor,
        order_books: %{my_order_book_feed: [:btcusd]},
        accounts: [:my_test_account],
        store: %{
          orders: [
            OrderSubmission.sell_limit(:my_test_account, :btcusd_success, 101.1, 0.1),
            OrderSubmission.sell_limit(:my_test_account, :btcusd_success, 10.1, 0.11),
            OrderSubmission.sell_limit(:my_test_account, :btcusd_insufficient_funds, 1.1, 0.1)
          ]
        }
      ]
    })

    snapshot = %OrderBook{
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }

    book_pid |> OrderBook.replace(snapshot)

    assert_receive {enqueued_order_1, %Advisor{}}
    assert_receive {enqueued_order_2, %Advisor{}}
    assert_receive {enqueued_order_3, %Advisor{}}

    assert enqueued_order_1.server_id == nil
    assert enqueued_order_1.account_id == :my_test_account
    assert enqueued_order_1.symbol == :btcusd_success
    assert enqueued_order_1.side == Order.sell()
    assert enqueued_order_1.type == Order.limit()
    assert enqueued_order_1.price == 101.1
    assert enqueued_order_1.size == 0.1
    assert enqueued_order_1.status == OrderStatus.enqueued()

    assert enqueued_order_2.server_id == nil
    assert enqueued_order_2.account_id == :my_test_account
    assert enqueued_order_2.symbol == :btcusd_success
    assert enqueued_order_2.side == Order.sell()
    assert enqueued_order_2.type == Order.limit()
    assert enqueued_order_2.price == 10.1
    assert enqueued_order_2.size == 0.11
    assert enqueued_order_2.status == OrderStatus.enqueued()

    assert enqueued_order_3.server_id == nil
    assert enqueued_order_3.account_id == :my_test_account
    assert enqueued_order_3.symbol == :btcusd_insufficient_funds
    assert enqueued_order_3.side == Order.sell()
    assert enqueued_order_3.type == Order.limit()
    assert enqueued_order_3.price == 1.1
    assert enqueued_order_3.size == 0.1
    assert enqueued_order_3.status == OrderStatus.enqueued()

    assert_receive {created_order_a, %Advisor{}}
    assert_receive {created_order_b, %Advisor{}}
    assert_receive {%OrderResponses.InsufficientFunds{}, error_order, %Advisor{}}

    [created_order_1, created_order_2] =
      [created_order_a, created_order_b]
      |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

    assert created_order_1.server_id != nil
    assert created_order_1.account_id == :my_test_account
    assert created_order_1.symbol == :btcusd_success
    assert created_order_1.side == Order.sell()
    assert created_order_1.type == Order.limit()
    assert created_order_1.price == 101.1
    assert created_order_1.size == 0.1
    assert created_order_1.status == OrderStatus.pending()

    assert created_order_2.server_id != nil
    assert created_order_2.account_id == :my_test_account
    assert created_order_2.symbol == :btcusd_success
    assert created_order_1.side == Order.sell()
    assert created_order_1.type == Order.limit()
    assert created_order_2.price == 10.1
    assert created_order_2.size == 0.11
    assert created_order_2.status == OrderStatus.pending()

    assert error_order.server_id == nil
    assert error_order.account_id == :my_test_account
    assert error_order.symbol == :btcusd_insufficient_funds
    assert error_order.side == Order.sell()
    assert error_order.type == Order.limit()
    assert error_order.price == 1.1
    assert error_order.size == 0.1
    assert error_order.status == OrderStatus.error()
  end

  test "handle_inside_quote can cancel orders", %{book_pid: book_pid} do
    start_supervised!({
      MyCancelOrdersAdvisor,
      [
        advisor_id: :my_cancel_orders_advisor,
        order_books: %{my_order_book_feed: [:btcusd]},
        accounts: [:my_test_account],
        store: %{}
      ]
    })

    snapshot = %OrderBook{
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }

    book_pid |> OrderBook.replace(snapshot)

    assert_receive {
      %Order{
        client_id: _,
        server_id: nil,
        account_id: :my_test_account,
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
        account_id: :my_test_account,
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
        account_id: :my_test_account,
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
        account_id: :my_test_account,
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

    assert_receive {
      %Order{
        client_id: _,
        server_id: _,
        account_id: :my_test_account,
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
        account_id: :my_test_account,
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
        account_id: :my_test_account,
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
        account_id: :my_test_account,
        symbol: :btcusd_success,
        price: 10.1,
        size: 0.11,
        status: :cancelled
      },
      %Advisor{}
    }
  end
end
