defmodule Tai.Exchanges.AssetBalanceChangeRequestTest do
  use ExUnit.Case, async: true
  doctest Tai.Exchanges.AssetBalanceChangeRequest

  describe "#new" do
    test "returns the struct with decimal values" do
      assert Tai.Exchanges.AssetBalanceChangeRequest.new(:btc, 0.1) ==
               %Tai.Exchanges.AssetBalanceChangeRequest{
                 asset: :btc,
                 amount: Decimal.new(0.1)
               }
    end
  end
end
