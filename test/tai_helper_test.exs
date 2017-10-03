require IEx;

defmodule TaiHelperTest do
  use ExUnit.Case
  doctest TaiHelper

  test "status is the sum of Bitcoin balances across all accounts as a formatted string" do
    assert TaiHelper.status() == "0.22 BTC"
  end
end
