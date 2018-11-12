defmodule Tai.Exchanges.AssetBalanceTest do
  use ExUnit.Case, async: true
  doctest Tai.Exchanges.AssetBalance

  describe "#total" do
    test "returns the sum of free and locked balances" do
      detail = %Tai.Exchanges.AssetBalance{
        exchange_id: :mock,
        account_id: :mock,
        asset: :mock,
        free: Decimal.new(0.1),
        locked: Decimal.new(0.2)
      }

      assert Tai.Exchanges.AssetBalance.total(detail) == Decimal.new(0.3)
    end
  end
end
