defmodule Tai.Events.UpsertAssetBalanceTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms decimal data to strings" do
    event = %Tai.Events.UpsertAssetBalance{
      venue_id: :my_venue,
      account_id: :my_account,
      asset: :btc,
      free: Decimal.new(0.1),
      locked: Decimal.new(0.2)
    }

    assert Tai.LogEvent.to_data(event) == %{
             venue_id: :my_venue,
             account_id: :my_account,
             asset: :btc,
             free: "0.1",
             locked: "0.2"
           }
  end
end
