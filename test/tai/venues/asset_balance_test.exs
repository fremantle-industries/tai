defmodule Tai.Venues.AssetBalanceTest do
  use ExUnit.Case, async: true
  doctest Tai.Venues.AssetBalance

  describe "#total" do
    test "returns the sum of free and locked balances" do
      detail = %Tai.Venues.AssetBalance{
        venue_id: :mock,
        account_id: :mock,
        asset: :mock,
        free: Decimal.new("0.1"),
        locked: Decimal.new("0.2")
      }

      assert Tai.Venues.AssetBalance.total(detail) == Decimal.new("0.3")
    end
  end
end
