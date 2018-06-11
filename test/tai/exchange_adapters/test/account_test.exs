defmodule Tai.ExchangeAdapters.Test.AccountTest do
  use ExUnit.Case, async: true
  doctest Tai.ExchangeAdapters.Test.Account

  alias Tai.Exchanges.Account
  alias Tai.Trading.{Order, OrderResponses, OrderStatus, TimeInForce}

  setup_all do
    start_supervised!({Tai.ExchangeAdapters.Test.Account, :my_test_account})

    :ok
  end

  describe "#all_balances" do
    test "returns an ok tuple with a map of symbols and their balances for the account" do
      assert Account.all_balances(:my_test_account) == {
               :ok,
               %{
                 bch: Decimal.new(0),
                 btc: Decimal.new("1.8122774027894548"),
                 eth: Decimal.new("0.000000000000200000000"),
                 ltc: Decimal.new("0.03")
               }
             }
    end
  end

  describe "#buy_limit" do
    test "returns an ok tuple with a pending order response successfully created" do
      assert {:ok, order_response} =
               Account.buy_limit(:my_test_account, :btcusd_success, 10.1, 2.2)

      assert order_response.id == "f9df7435-34d5-4861-8ddc-80f0fd2c83d7"
      assert order_response.status == :pending
    end

    test "can take an order struct" do
      order = %Order{
        client_id: UUID.uuid4(),
        account_id: :my_test_account,
        symbol: :btcusd_success,
        side: Order.buy(),
        type: Order.limit(),
        price: 10.1,
        size: 2.2,
        status: OrderStatus.enqueued(),
        enqueued_at: Timex.now(),
        time_in_force: TimeInForce.good_til_canceled()
      }

      assert {:ok, order_response} = Account.buy_limit(order)
      assert order_response.id == "f9df7435-34d5-4861-8ddc-80f0fd2c83d7"
      assert order_response.status == :pending
    end

    test "returns an error tuple when it is not the correct side or type" do
      buy_market_order = %Order{
        client_id: UUID.uuid4(),
        account_id: :my_test_account,
        symbol: :btcusd_success,
        side: Order.buy(),
        type: :market,
        price: 10.1,
        size: 2.2,
        status: OrderStatus.enqueued(),
        enqueued_at: Timex.now(),
        time_in_force: TimeInForce.good_til_canceled()
      }

      sell_limit_order = %Order{
        client_id: UUID.uuid4(),
        account_id: :my_test_account,
        symbol: :btcusd_success,
        side: Order.sell(),
        type: Order.limit(),
        price: 10.1,
        size: 2.2,
        status: OrderStatus.enqueued(),
        enqueued_at: Timex.now(),
        time_in_force: TimeInForce.good_til_canceled()
      }

      assert {:error, %OrderResponses.InvalidOrderType{}} = Account.buy_limit(buy_market_order)
      assert {:error, %OrderResponses.InvalidOrderType{}} = Account.buy_limit(sell_limit_order)
    end

    test "returns an error tuple when an order fails" do
      assert {
               :error,
               %Tai.Trading.InsufficientBalanceError{}
             } = Account.buy_limit(:my_test_account, :btcusd_insufficient_funds, 10.1, 2.1)
    end

    test "returns an unknown error tuple when it can't find a match" do
      assert Account.buy_limit(:my_test_account, :btcusd, 101.1, 0.1) == {:error, :unknown_error}
    end
  end

  describe "#sell_limit" do
    test "returns an ok tuple when an order is successfully created" do
      assert {:ok, order_response} =
               Account.sell_limit(:my_test_account, :btcusd_success, 10.1, 2.2)

      assert order_response.id == "41541912-ebc1-4173-afa5-4334ccf7a1a8"
      assert order_response.status == :pending
    end

    test "can take an order struct" do
      order = %Order{
        client_id: UUID.uuid4(),
        account_id: :my_test_account,
        symbol: :btcusd_success,
        side: Order.sell(),
        type: Order.limit(),
        price: 10.1,
        size: 2.2,
        status: OrderStatus.enqueued(),
        enqueued_at: Timex.now(),
        time_in_force: TimeInForce.good_til_canceled()
      }

      assert {:ok, order_response} = Account.sell_limit(order)
      assert order_response.id == "41541912-ebc1-4173-afa5-4334ccf7a1a8"
      assert order_response.status == :pending
    end

    test "returns an error tuple when it is not the correct side or type" do
      sell_market_order = %Order{
        client_id: UUID.uuid4(),
        account_id: :my_test_account,
        symbol: :btcusd_success,
        side: Order.sell(),
        type: :market,
        price: 10.1,
        size: 2.2,
        status: OrderStatus.enqueued(),
        enqueued_at: Timex.now(),
        time_in_force: TimeInForce.good_til_canceled()
      }

      buy_limit_order = %Order{
        client_id: UUID.uuid4(),
        account_id: :my_test_account,
        symbol: :btcusd_success,
        side: Order.buy(),
        type: Order.limit(),
        price: 10.1,
        size: 2.2,
        status: OrderStatus.enqueued(),
        enqueued_at: Timex.now(),
        time_in_force: TimeInForce.good_til_canceled()
      }

      assert {:error, %OrderResponses.InvalidOrderType{}} = Account.sell_limit(sell_market_order)
      assert {:error, %OrderResponses.InvalidOrderType{}} = Account.sell_limit(buy_limit_order)
    end

    test "returns an {:error, reason} tuple when an order fails" do
      assert {
               :error,
               %Tai.Trading.InsufficientBalanceError{}
             } = Account.sell_limit(:my_test_account, :btcusd_insufficient_funds, 10.1, 2.1)
    end

    test "sell_limit returns an unknown error tuple when it can't find a matching symbol" do
      assert Account.sell_limit(:my_test_account, :btcusd, 101.1, 0.1) == {:error, :unknown_error}
    end
  end

  describe "#order_status" do
    test "returns an {:ok, status} tuple when it finds the order on the given account" do
      assert Account.order_status(:my_test_account, "f9df7435-34d5-4861-8ddc-80f0fd2c83d7") ==
               {:ok, :open}
    end

    test "return an {:error, reason} tuple when the order doesn't exist" do
      assert Account.order_status(:my_test_account, "invalid-order-id") ==
               {:error, "Invalid order id"}
    end
  end

  describe "#cancel_order" do
    test "cancels a previous order" do
      assert Account.cancel_order(:my_test_account, "f9df7435-34d5-4861-8ddc-80f0fd2c83d7") ==
               {:ok, "f9df7435-34d5-4861-8ddc-80f0fd2c83d7"}
    end

    test "displays error messages" do
      assert Account.cancel_order(:my_test_account, "invalid-order-id") ==
               {:error, "Invalid order id"}
    end
  end
end
