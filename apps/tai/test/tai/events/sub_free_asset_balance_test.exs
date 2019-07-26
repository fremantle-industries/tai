defmodule Tai.Events.SubFreeAssetBalanceTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms decimal data to strings" do
    event = %Tai.Events.SubFreeAssetBalance{
      venue_id: :my_venue,
      account_id: :my_account,
      asset: :btc,
      val: Decimal.new("0.1"),
      free: Decimal.new("0.2"),
      locked: Decimal.new("0.3")
    }

    assert Tai.LogEvent.to_data(event) == %{
             venue_id: :my_venue,
             account_id: :my_account,
             asset: :btc,
             val: "0.1",
             free: "0.2",
             locked: "0.3"
           }
  end
end
