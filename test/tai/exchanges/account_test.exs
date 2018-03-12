defmodule Tai.Exchanges.AccountTest do
  use ExUnit.Case
  doctest Tai.Exchanges.Account

  alias Tai.Exchanges.Account

  test "balance returns the USD value of all assets on the given exchange" do
    assert Account.balance(:test_exchange_a) == Decimal.new(0.11)
  end

  test "buy_limit returns an {:ok, response} tuple when an order is successfully created" do
    assert Account.buy_limit(:test_exchange_a, :btcusd, 10.1, 2.2) == {
      :ok,
      %Tai.OrderResponse{id: "f9df7435-34d5-4861-8ddc-80f0fd2c83d7", status: :pending}
    }
  end

  test "buy_limit returns an {:error, reason} tuple when an order fails" do
    assert Account.buy_limit(:test_exchange_a, :btcusd, 10.1, 2.1) == {:error, "Insufficient funds"}
  end

  test "sell_limit returns an {:ok, response} tuple when an order is successfully created" do
    assert Account.sell_limit(:test_exchange_a, :btcusd, 10.1, 2.2) == {
      :ok,
      %Tai.OrderResponse{id: "41541912-ebc1-4173-afa5-4334ccf7a1a8", status: :pending}
    }
  end

  test "sell_limit returns an {:error, reason} tuple when an order fails" do
    assert Account.sell_limit(:test_exchange_a, :btcusd, 10.1, 2.1) == {:error, "Insufficient funds"}
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
