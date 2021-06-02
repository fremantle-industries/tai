defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.AccountsTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  @venue :my_venue
  @credential :main
  @received_at Tai.Time.monotonic_time()

  setup do
    start_supervised!({ProcessAuth, [venue: @venue, credential: {@credential, %{}}]})
    {:ok, _} = insert_account(%{asset: :btc, type: "default"})
    TaiEvents.firehose_subscribe()
    Tai.SystemBus.subscribe(:account_store)
    :ok
  end

  test "updates the existing account using the margin balance" do
    data = [%{
      "account" => 158_677,
      "currency" => "XBt",
      "marginBalance" => 133_558_098,
      "available" => 111_558_098,
      "timestamp" => "2020-03-09T01:56:35.455Z"
    }]

    cast_margin_msg(data, "update")

    assert_receive {:account_store, :after_put, updated_account}
    assert updated_account.equity == Decimal.new("1.33558098")
    assert updated_account.locked == Decimal.new("1.33558098")
  end

  test "updates the existing account using the available balance" do
    data = [%{
      "account" => 158_677,
      "currency" => "XBt",
      "availableMargin" => 111_558_098,
      "timestamp" => "2020-03-09T01:56:35.455Z"
    }]

    cast_margin_msg(data, "update")

    assert_receive {:account_store, :after_put, updated_account}
    assert updated_account.equity == Decimal.new("1.11558098")
    assert updated_account.locked == Decimal.new("1.11558098")
  end

  test "ignores account update with no margin data" do
    data = [%{
      "account" => 158_677,
      "currency" => "XBt",
      "grossOpenCost" => 79542,
      "riskValue" => 79542,
      "timestamp" => "2021-03-16T13:56:53.020Z"
    }]

    cast_margin_msg(data, "update")

    refute_receive {:account_store, :after_put, _}
  end

  test "ignores partial and insert messsages" do
    data = [%{
      "account" => 158_677,
      "currency" => "XBt",
      "availableMargin" => 111_558_098,
      "timestamp" => "2020-03-09T01:56:35.455Z"
    }]

    cast_margin_msg(data, "partial")
    refute_receive {:account_store, :after_put, _}

    cast_margin_msg(data, "insert")
    refute_receive {:account_store, :after_put, _}
  end

  defp insert_account(attrs) do
    merged_attrs = Map.merge(%{venue_id: @venue, credential_id: @credential}, attrs)
    account = struct(Tai.Venues.Account, merged_attrs)
    Tai.Venues.AccountStore.put(account)
  end

  defp cast_margin_msg(data, action) do
    msg = %{
      "table" => "margin",
      "action" => action,
      "data" => data
    }

    @venue
    |> ProcessAuth.process_name()
    |> GenServer.cast({msg, @received_at})
  end
end
