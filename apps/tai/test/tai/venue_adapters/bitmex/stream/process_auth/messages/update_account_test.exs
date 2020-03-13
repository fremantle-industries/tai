defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateAccountTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  @venue :venue_a
  @credential_id :main
  @credential {@credential_id, %{}}

  setup do
    start_supervised!({Tai.SystemBus, 1})
    start_supervised!(Tai.Venues.AccountStore)
    start_supervised!({ProcessAuth, [venue: @venue, credential: @credential]})
    :ok
  end

  test "updates equity & locked on the existing account" do
    {:ok, _} =
      Tai.Venues.Account
      |> struct(venue_id: @venue, credential_id: @credential_id, asset: :btc, type: "default")
      |> Tai.Venues.AccountStore.put()

    Tai.SystemBus.subscribe(:account_store)

    venue_msg = %{
      "table" => "margin",
      "action" => "update",
      "data" => [
        %{
          "account" => 158_677,
          "currency" => "XBt",
          "marginBalance" => 133_558_098,
          "timestamp" => "2020-03-09T01:56:35.455Z"
        }
      ]
    }

    @venue
    |> ProcessAuth.to_name()
    |> GenServer.cast({venue_msg, Timex.now()})

    assert_receive {:account_store, :after_put, updated_account}
    assert updated_account.equity == Decimal.new("1.33558098")
    assert updated_account.locked == Decimal.new("1.33558098")
  end
end
