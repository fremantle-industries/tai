defmodule Tai.VenueAdapters.Bitmex.Stream.TradeTest do
  use Tai.TestSupport.DataCase, async: false
  import Tai.TestSupport.Assertions.Event
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessOptionalChannels

  setup do
    start_supervised!({ProcessOptionalChannels, [venue_id: :my_venue]})
    :ok
  end

  test "broadcasts an event when public trade is received" do
    TaiEvents.firehose_subscribe()
    venue_trade_id = Ecto.UUID.generate()

    venue_trades = [
      %{
        "timestamp" => "2019-09-13T07:25:39.207Z",
        "symbol" => "XBTUSD",
        "side" => "Buy",
        "size" => 0,
        "price" => 0,
        "tickDirection" => "string",
        "trdMatchID" => venue_trade_id,
        "grossValue" => 0,
        "homeNotional" => 0,
        "foreignNotional" => 0
      }
    ]

    :my_venue
    |> ProcessOptionalChannels.to_name()
    |> GenServer.cast(
      {%{"table" => "trade", "action" => "insert", "data" => venue_trades}, :ignore}
    )

    assert_event(%Tai.Events.Trade{} = event)
    assert event.venue_trade_id == venue_trade_id
  end
end
