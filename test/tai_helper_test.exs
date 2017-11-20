require IEx;

defmodule TaiHelperTest do
  use ExUnit.Case
  doctest TaiHelper

  import ExUnit.CaptureIO

  test "status is the sum of USD balances across accounts as a formatted string" do
    assert capture_io(fn ->
      TaiHelper.status
    end) == "0.22 USD\n"
  end

  test "quotes returns the orderbook for the exchange and symbol" do
    assert capture_io(fn ->
      TaiHelper.quotes(:test_exchange_a, :btcusd)
    end) == "8003.22/0.66 [0.000143s]\n---\n8003.21/1.55 [0.001044s]\n\n"
  end

  test "buy_limit creates an order on the exchange" do
    assert capture_io(fn ->
      TaiHelper.buy_limit(:test_exchange_a, :btcusd, 10.1, 2.2)
    end) == "created id: f9df7435-34d5-4861-8ddc-80f0fd2c83d7, status: pending\n"
  end
end
