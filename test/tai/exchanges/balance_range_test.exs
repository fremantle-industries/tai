defmodule Tai.Exchanges.BalanceRangeTest do
  use ExUnit.Case, async: true

  describe "#new" do
    test "can take integers, floats, strings & decimals for min and max" do
      assert %Tai.Exchanges.BalanceRange{} = Tai.Exchanges.BalanceRange.new(:btc, 1.0, 1.0)
      assert %Tai.Exchanges.BalanceRange{} = Tai.Exchanges.BalanceRange.new(:btc, 1, 1)
      assert %Tai.Exchanges.BalanceRange{} = Tai.Exchanges.BalanceRange.new(:btc, "1", "1")

      assert %Tai.Exchanges.BalanceRange{} =
               Tai.Exchanges.BalanceRange.new(:btc, Decimal.new(1), Decimal.new(1))

      assert_raise FunctionClauseError, fn -> Tai.Exchanges.BalanceRange.new(:btc, nil, nil) end
    end
  end

  describe "#validate" do
    test "returns :ok when valid" do
      range = Tai.Exchanges.BalanceRange.new(:btc, 1.0, 1.1)
      assert Tai.Exchanges.BalanceRange.validate(range) == :ok
    end

    test "returns an error tuple when min < 0" do
      range = Tai.Exchanges.BalanceRange.new(:btc, -0.1, 1)
      assert Tai.Exchanges.BalanceRange.validate(range) == {:error, :min_less_than_zero}
    end

    test "returns an error tuple when min > max" do
      range = Tai.Exchanges.BalanceRange.new(:btc, 1.1, 1)
      assert Tai.Exchanges.BalanceRange.validate(range) == {:error, :min_greater_than_max}
    end
  end
end
