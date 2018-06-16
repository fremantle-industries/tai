defmodule Tai.Exchanges.BalanceDetailTest do
  use ExUnit.Case, async: true
  doctest Tai.Exchanges.BalanceDetail

  describe "#new" do
    test "returns the struct with decimal values" do
      assert Tai.Exchanges.BalanceDetail.new(0.1, 0.2) == %Tai.Exchanges.BalanceDetail{
               free: Decimal.new(0.1),
               locked: Decimal.new(0.2)
             }
    end
  end

  describe "#total" do
    test "returns the sum of free and locked balances" do
      detail = %Tai.Exchanges.BalanceDetail{
        free: Decimal.new(0.1),
        locked: Decimal.new(0.2)
      }

      assert Tai.Exchanges.BalanceDetail.total(detail) == Decimal.new(0.3)
    end
  end
end
