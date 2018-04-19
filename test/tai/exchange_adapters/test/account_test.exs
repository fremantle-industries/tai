defmodule Tai.ExchangeAdapters.Test.AccountTest do
  use ExUnit.Case, async: true
  doctest Tai.ExchangeAdapters.Test.Account

  alias Tai.{Exchanges.Account, Trading.OrderResponses}

  setup_all do
    start_supervised!({Tai.ExchangeAdapters.Test.Account, :my_test_exchange})

    :ok
  end

  test "balance returns a decimal" do
    assert Account.balance(:my_test_exchange) == Decimal.new(0.11)
  end

  test "buy_limit returns an :ok, created_response tuple when the symbol is :btcusd_success" do
    {:ok, order_response} = Account.buy_limit(:my_test_exchange, :btcusd_success, 101.1, 0.1)

    assert order_response.id == "f9df7435-34d5-4861-8ddc-80f0fd2c83d7"
    assert order_response.status == :pending
    assert %DateTime{} = order_response.created_at
  end

  test "buy_limit returns an :error, insufficient_funds tuple when the symbol is :btcusd_insufficient_funds" do
    assert Account.buy_limit(:my_test_exchange, :btcusd_insufficient_funds, 101.1, 0.1) == {
             :error,
             %OrderResponses.InsufficientFunds{}
           }
  end

  test "buy_limit returns an :error, unknown_error tuple otherwise" do
    assert Account.buy_limit(:my_test_exchange, :btcusd, 101.1, 0.1) == {:error, :unknown_error}
  end

  test "sell_limit returns an :ok, created_response tuple when the symbol is :btcusd_success" do
    {:ok, order_response} = Account.sell_limit(:my_test_exchange, :btcusd_success, 101.1, 0.1)

    assert order_response.id == "41541912-ebc1-4173-afa5-4334ccf7a1a8"
    assert order_response.status == :pending
    assert %DateTime{} = order_response.created_at
  end

  test "sell_limit returns an :error, insufficient_funds tuple when the symbol is :btcusd_insufficient_funds" do
    assert Account.sell_limit(:my_test_exchange, :btcusd_insufficient_funds, 101.1, 0.1) == {
             :error,
             %OrderResponses.InsufficientFunds{}
           }
  end

  test "sell_limit returns an :error, unknown_error tuple otherwise" do
    assert Account.sell_limit(:my_test_exchange, :btcusd, 101.1, 0.1) == {:error, :unknown_error}
  end

  test "order_status can return an invalid order id" do
    assert Account.order_status(:my_test_exchange, "invalid-order-id") == {
             :error,
             "Invalid order id"
           }
  end

  test "order_status returns an ok tuple for all other order ids" do
    assert Account.order_status(:my_test_exchange, "some-other-order-id") == {:ok, :open}
  end

  test "cancel_order can return an invalid order id" do
    assert Account.cancel_order(:my_test_exchange, "invalid-order-id") == {
             :error,
             "Invalid order id"
           }
  end

  test "cancel_order returns an ok tuple for all other order ids" do
    assert Account.cancel_order(:my_test_exchange, "some-other-order-id") == {
             :ok,
             "some-other-order-id"
           }
  end
end
