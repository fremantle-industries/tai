require IEx;

defmodule Tai.CommandsHelperTest do
  use ExUnit.Case
  doctest Tai.CommandsHelper

  import ExUnit.CaptureIO

  test "status is the sum of USD balances across accounts as a formatted string" do
    assert capture_io(fn ->
      Tai.CommandsHelper.status
    end) == "0.22 USD\n"
  end

  test "quotes returns the orderbook for the exchange and symbol" do
    assert capture_io(fn ->
      Tai.CommandsHelper.quotes(:test_exchange_a, :btcusd)
    end) == "8003.22/0.66 [0.000143s]\n---\n8003.21/1.55 [0.001044s]\n\n"
  end

  test "buy_limit creates an order on the exchange then displays it's 'id' and 'status'" do
    assert capture_io(fn ->
      Tai.CommandsHelper.buy_limit(:test_exchange_a, :btcusd, 10.1, 2.2)
    end) == "create order success - id: f9df7435-34d5-4861-8ddc-80f0fd2c83d7, status: pending\n"
  end

  test "buy_limit displays an error message when the order can't be created" do
    assert capture_io(fn ->
      Tai.CommandsHelper.buy_limit(:test_exchange_a, :btcusd, 10.1, 3.3)
    end) == "create order failure - Insufficient funds\n"
  end

  test "order_status displays the order info" do
    assert capture_io(fn ->
      Tai.CommandsHelper.order_status(:test_exchange_a, "f9df7435-34d5-4861-8ddc-80f0fd2c83d7")
    end) == "status: open\n"
  end

  test "order_status displays error messages" do
    assert capture_io(fn ->
      Tai.CommandsHelper.order_status(:test_exchange_a, "invalid-id")
    end) == "error: Invalid order id\n"
  end
end
