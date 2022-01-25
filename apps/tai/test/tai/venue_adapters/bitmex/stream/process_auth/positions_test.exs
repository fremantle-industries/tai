defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.PositionsTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  @venue :my_venue
  @credential :main
  @received_at Tai.Time.monotonic_time()

  setup do
    start_supervised!({ProcessAuth, [venue: @venue, credential: {@credential, %{}}]})
    {:ok, _} = insert_position(%{product_symbol: :xbtusd, qty: Decimal.new(1)})
    TaiEvents.firehose_subscribe()
    :ok = Tai.SystemBus.subscribe(:position_store)
    :ok
  end

  test "updates equity & locked on the existing position" do
    data = [
      %{
        "account" => 158_677,
        "currency" => "XBt",
        "currentQty" => 2,
        "currentTimestamp" => "2020-03-13T23:30:05.364Z",
        "lastPrice" => 5656.81,
        "liquidationPrice" => 1,
        "maintMargin" => 138,
        "markPrice" => 5656.81,
        "posComm" => 14,
        "posMaint" => 123,
        "posMargin" => 5473,
        "symbol" => "XBTUSD",
        "timestamp" => "2020-03-13T23:30:05.364Z"
      }
    ]

    cast_position_msg(data, "update")

    assert_receive {:position_store, :after_put, updated_position}
    assert updated_position.qty == Decimal.new(2)
  end

  test "ignores partial and insert messsages" do
    data = [%{
        "account" => 158_677,
        "currency" => "XBt",
        "currentQty" => 2,
        "currentTimestamp" => "2020-03-13T23:30:05.364Z",
        "lastPrice" => 5656.81,
        "liquidationPrice" => 1,
        "maintMargin" => 138,
        "markPrice" => 5656.81,
        "posComm" => 14,
        "posMaint" => 123,
        "posMargin" => 5473,
        "symbol" => "XBTUSD",
        "timestamp" => "2020-03-13T23:30:05.364Z"
    }]

    cast_position_msg(data, "partial")
    refute_receive {:position_store, :after_put, _}

    cast_position_msg(data, "insert")
    refute_receive {:position_store, :after_put, _}
  end

  defp insert_position(attrs) do
    merged_attrs = Map.merge(%{venue_id: @venue, credential_id: @credential}, attrs)
    position = struct(Tai.Trading.Position, merged_attrs)
    Tai.Trading.PositionStore.put(position)
  end

  defp cast_position_msg(data, action) do
    msg = %{
      "table" => "position",
      "action" => action,
      "data" => data
    }

    @venue
    |> ProcessAuth.process_name()
    |> GenServer.cast({msg, @received_at})
  end
end
