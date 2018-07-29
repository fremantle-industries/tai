defmodule Tai.Exchanges.AssetBalanceTest do
  use ExUnit.Case, async: true
  doctest Tai.Exchanges.AssetBalance

  describe "#new" do
    test "returns the struct with decimal values" do
      assert Tai.Exchanges.AssetBalance.new(0.1, 0.2) == %Tai.Exchanges.AssetBalance{
               free: Decimal.new(0.1),
               locked: Decimal.new(0.2)
             }
    end
  end

  describe "#total" do
    test "returns the sum of free and locked balances" do
      detail = %Tai.Exchanges.AssetBalance{
        free: Decimal.new(0.1),
        locked: Decimal.new(0.2)
      }

      assert Tai.Exchanges.AssetBalance.total(detail) == Decimal.new(0.3)
    end
  end
end
