defmodule Tai.Exchanges.LockRequestTest do
  use ExUnit.Case, async: true
  doctest Tai.Exchanges.LockRequest

  describe "#new" do
    test "returns the struct with decimal values" do
      assert Tai.Exchanges.LockRequest.new(:btc, 0.1) ==
               %Tai.Exchanges.LockRequest{
                 asset: :btc,
                 amount: Decimal.new(0.1)
               }
    end
  end
end
