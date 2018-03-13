defmodule Tai.Exchanges.AccountTest do
  use ExUnit.Case
  doctest Tai.Exchanges.Account

  alias Tai.{Exchanges.Account, Trading.OrderResponses}

  test "balance returns the USD value of all assets on the given exchange" do
    assert Account.balance(:test_exchange_a) == Decimal.new(0.11)
  end

  test "buy_limit returns an {:ok, response} tuple when an order is successfully created" do
    assert {:ok, order_response} = Account.buy_limit(:test_exchange_a, :btcusd_success, 10.1, 2.2)
    assert order_response.id == "f9df7435-34d5-4861-8ddc-80f0fd2c83d7"
    assert order_response.status == :pending
    assert %DateTime{} = order_response.created_at
  end

  test "buy_limit returns an {:error, reason} tuple when an order fails" do
    assert Account.buy_limit(:test_exchange_a, :btcusd_insufficient_funds, 10.1, 2.1) == {
      :error,
      %OrderResponses.InsufficientFunds{}
    }
  end

  test "sell_limit returns an {:ok, response} tuple when an order is successfully created" do
    assert {:ok, order_response} = Account.sell_limit(:test_exchange_a, :btcusd_success, 10.1, 2.2)
    assert order_response.id == "41541912-ebc1-4173-afa5-4334ccf7a1a8"
    assert order_response.status == :pending
    assert %DateTime{} = order_response.created_at
  end

  test "sell_limit returns an {:error, reason} tuple when an order fails" do
    assert Account.sell_limit(:test_exchange_a, :btcusd_insufficient_funds, 10.1, 2.1) == {
      :error,
      %OrderResponses.InsufficientFunds{}
    }
  end

  test "order_status returns an {:ok, status} tuple when it finds the order on the given exchange" do
    assert Account.order_status(:test_exchange_a, "f9df7435-34d5-4861-8ddc-80f0fd2c83d7") == {:ok, :open}
  end

  test "order_status return an {:error, reason} tuple when the order doesn't exist" do
    assert Account.order_status(:test_exchange_a, "invalid-order-id") == {:error, "Invalid order id"}
  end

  test "cancel_order cancels a previous order" do
    assert Account.cancel_order(:test_exchange_a, "f9df7435-34d5-4861-8ddc-80f0fd2c83d7") == {:ok, "f9df7435-34d5-4861-8ddc-80f0fd2c83d7"}
  end

  test "cancel_order displays error messages" do
    assert Account.cancel_order(:test_exchange_a, "invalid-order-id") == {:error, "Invalid order id"}
  end
end
