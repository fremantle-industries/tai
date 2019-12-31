defmodule Tai.Venues.AccountTest do
  use ExUnit.Case, async: true
  doctest Tai.Venues.Account

  describe "#total" do
    test "returns the sum of free and locked balances" do
      account = %Tai.Venues.Account{
        venue_id: :mock,
        credential_id: :mock,
        asset: :mock,
        type: "default",
        free: Decimal.new("0.1"),
        locked: Decimal.new("0.2")
      }

      assert Tai.Venues.Account.total(account) == Decimal.new("0.3")
    end
  end
end
