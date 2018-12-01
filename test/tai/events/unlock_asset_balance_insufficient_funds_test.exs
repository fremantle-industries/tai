defmodule Tai.Events.UnlockAssetBalanceInsufficientFundsTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms decimal data to strings" do
    event = %Tai.Events.UnlockAssetBalanceInsufficientFunds{
      venue_id: :my_venue,
      account_id: :my_account,
      asset: :btc,
      qty: Decimal.new("0.1"),
      locked: Decimal.new("0.2")
    }

    assert Tai.LogEvent.to_data(event) == %{
             venue_id: :my_venue,
             account_id: :my_account,
             asset: :btc,
             qty: "0.1",
             locked: "0.2"
           }
  end
end
