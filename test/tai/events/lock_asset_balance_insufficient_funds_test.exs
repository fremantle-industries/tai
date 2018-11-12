defmodule Tai.Events.LockAssetBalanceInsufficientFundsTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms decimal data to strings" do
    event = %Tai.Events.LockAssetBalanceInsufficientFunds{
      venue_id: :my_venue,
      account_id: :my_account,
      asset: :btc,
      min: Decimal.new(0.1),
      max: Decimal.new(0.3),
      free: Decimal.new(0.2)
    }

    assert Tai.LogEvent.to_data(event) == %{
             venue_id: :my_venue,
             account_id: :my_account,
             asset: :btc,
             min: "0.1",
             max: "0.3",
             free: "0.2"
           }
  end
end
