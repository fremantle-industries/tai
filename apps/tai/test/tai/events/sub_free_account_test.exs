defmodule Tai.Events.SubFreeAccountTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms decimal data to strings" do
    event = %Tai.Events.SubFreeAccount{
      venue_id: :my_venue,
      credential_id: :my_credential,
      asset: :btc,
      val: Decimal.new("0.1"),
      free: Decimal.new("0.2"),
      locked: Decimal.new("0.3")
    }

    assert Tai.LogEvent.to_data(event) == %{
             venue_id: :my_venue,
             credential_id: :my_credential,
             asset: :btc,
             val: "0.1",
             free: "0.2",
             locked: "0.3"
           }
  end
end
