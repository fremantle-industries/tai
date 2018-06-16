defmodule Tai.Exchanges.HoldRequestTest do
  use ExUnit.Case, async: true
  doctest Tai.Exchanges.HoldRequest

  describe "#new" do
    test "returns the struct with decimal values" do
      assert Tai.Exchanges.HoldRequest.new(:my_test_account, :btc, 0.1) ==
               %Tai.Exchanges.HoldRequest{
                 account_id: :my_test_account,
                 asset: :btc,
                 amount: Decimal.new(0.1)
               }
    end
  end
end
