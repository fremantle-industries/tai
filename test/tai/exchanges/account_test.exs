defmodule Tai.Exchanges.AccountTest do
  use ExUnit.Case
  doctest Tai.Exchanges.Account

  alias Tai.Exchanges.Account
  alias Tai.Trading.{OrderResponses, Order, OrderStatus}

  test "balance returns the USD value of all assets on the given account" do
    assert Account.balance(:test_account_a) == Decimal.new(0.11)
  end

  test "buy_limit returns an ok tuple when an order is successfully created" do
    assert {:ok, order_response} = Account.buy_limit(:test_account_a, :btcusd_success, 10.1, 2.2)
    assert order_response.id == "f9df7435-34d5-4861-8ddc-80f0fd2c83d7"
    assert order_response.status == :pending
    assert %DateTime{} = order_response.created_at
  end

  test "buy_limit can take an order struct" do
    order = %Order{
      client_id: UUID.uuid4(),
      account_id: :test_account_a,
      symbol: :btcusd_success,
      side: Order.buy(),
      type: Order.limit(),
      price: 10.1,
      size: 2.2,
      status: OrderStatus.enqueued(),
      enqueued_at: Timex.now()
    }

    assert {:ok, order_response} = Account.buy_limit(order)
    assert order_response.id == "f9df7435-34d5-4861-8ddc-80f0fd2c83d7"
    assert order_response.status == :pending
    assert %DateTime{} = order_response.created_at
  end

  test "buy_limit returns an error tuple when it is not the correct side or type" do
    buy_market_order = %Order{
      client_id: UUID.uuid4(),
      account_id: :test_account_a,
      symbol: :btcusd_success,
      side: Order.buy(),
      type: :market,
      price: 10.1,
      size: 2.2,
      status: OrderStatus.enqueued(),
      enqueued_at: Timex.now()
    }

    sell_limit_order = %Order{
      client_id: UUID.uuid4(),
      account_id: :test_account_a,
      symbol: :btcusd_success,
      side: Order.sell(),
      type: Order.limit(),
      price: 10.1,
      size: 2.2,
      status: OrderStatus.enqueued(),
      enqueued_at: Timex.now()
    }

    assert {:error, %OrderResponses.InvalidOrderType{}} = Account.buy_limit(buy_market_order)
    assert {:error, %OrderResponses.InvalidOrderType{}} = Account.buy_limit(sell_limit_order)
  end

  test "buy_limit returns an error tuple when an order fails" do
    assert Account.buy_limit(:test_account_a, :btcusd_insufficient_funds, 10.1, 2.1) == {
             :error,
             %OrderResponses.InsufficientFunds{}
           }
  end

  test "sell_limit returns an ok tuple when an order is successfully created" do
    assert {:ok, order_response} = Account.sell_limit(:test_account_a, :btcusd_success, 10.1, 2.2)

    assert order_response.id == "41541912-ebc1-4173-afa5-4334ccf7a1a8"
    assert order_response.status == :pending
    assert %DateTime{} = order_response.created_at
  end

  test "sell_limit can take an order struct" do
    order = %Order{
      client_id: UUID.uuid4(),
      account_id: :test_account_a,
      symbol: :btcusd_success,
      side: Order.sell(),
      type: Order.limit(),
      price: 10.1,
      size: 2.2,
      status: OrderStatus.enqueued(),
      enqueued_at: Timex.now()
    }

    assert {:ok, order_response} = Account.sell_limit(order)
    assert order_response.id == "41541912-ebc1-4173-afa5-4334ccf7a1a8"
    assert order_response.status == :pending
    assert %DateTime{} = order_response.created_at
  end

  test "sell_limit returns an error tuple when it is not the correct side or type" do
    sell_market_order = %Order{
      client_id: UUID.uuid4(),
      account_id: :test_account_a,
      symbol: :btcusd_success,
      side: Order.sell(),
      type: :market,
      price: 10.1,
      size: 2.2,
      status: OrderStatus.enqueued(),
      enqueued_at: Timex.now()
    }

    buy_limit_order = %Order{
      client_id: UUID.uuid4(),
      account_id: :test_account_a,
      symbol: :btcusd_success,
      side: Order.buy(),
      type: Order.limit(),
      price: 10.1,
      size: 2.2,
      status: OrderStatus.enqueued(),
      enqueued_at: Timex.now()
    }

    assert {:error, %OrderResponses.InvalidOrderType{}} = Account.sell_limit(sell_market_order)
    assert {:error, %OrderResponses.InvalidOrderType{}} = Account.sell_limit(buy_limit_order)
  end

  test "sell_limit returns an {:error, reason} tuple when an order fails" do
    assert Account.sell_limit(:test_account_a, :btcusd_insufficient_funds, 10.1, 2.1) == {
             :error,
             %OrderResponses.InsufficientFunds{}
           }
  end

  test "order_status returns an {:ok, status} tuple when it finds the order on the given account" do
    assert Account.order_status(:test_account_a, "f9df7435-34d5-4861-8ddc-80f0fd2c83d7") ==
             {:ok, :open}
  end

  test "order_status return an {:error, reason} tuple when the order doesn't exist" do
    assert Account.order_status(:test_account_a, "invalid-order-id") ==
             {:error, "Invalid order id"}
  end

  test "cancel_order cancels a previous order" do
    assert Account.cancel_order(:test_account_a, "f9df7435-34d5-4861-8ddc-80f0fd2c83d7") ==
             {:ok, "f9df7435-34d5-4861-8ddc-80f0fd2c83d7"}
  end

  test "cancel_order displays error messages" do
    assert Account.cancel_order(:test_account_a, "invalid-order-id") ==
             {:error, "Invalid order id"}
  end
end
