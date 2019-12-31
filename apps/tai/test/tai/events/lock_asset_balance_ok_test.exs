defmodule Tai.Events.LockAssetBalanceOkTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms decimal data to strings" do
    event = %Tai.Events.LockAssetBalanceOk{
      venue_id: :my_venue,
      credential_id: :my_credential,
      asset: :btc,
      min: Decimal.new("0.1"),
      max: Decimal.new("0.3"),
      qty: Decimal.new("0.2")
    }

    assert Tai.LogEvent.to_data(event) == %{
             venue_id: :my_venue,
             credential_id: :my_credential,
             asset: :btc,
             min: "0.1",
             max: "0.3",
             qty: "0.2"
           }
  end
end
