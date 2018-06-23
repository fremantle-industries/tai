defmodule Tai.Exchanges.BalanceChangeRequestTest do
  use ExUnit.Case, async: true
  doctest Tai.Exchanges.BalanceChangeRequest

  describe "#new" do
    test "returns the struct with decimal values" do
      assert Tai.Exchanges.BalanceChangeRequest.new(:btc, 0.1) ==
               %Tai.Exchanges.BalanceChangeRequest{
                 asset: :btc,
                 amount: Decimal.new(0.1)
               }
    end
  end
end
