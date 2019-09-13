defmodule Tai.VenueAdapters.OkEx.Stream.TradeTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Assertions.Event
  alias Tai.VenueAdapters.OkEx.Stream.ProcessMessages
  alias Tai.Events

  setup do
    start_supervised!({Tai.Events, 1})
    start_supervised!({ProcessMessages, [venue: :my_venue]})
    :ok
  end

  test "broadcasts an event when public trade is received" do
    Events.firehose_subscribe()
    venue_trade_id = Ecto.UUID.generate()

    venue_trades = [
      %{
        "side" => "buy",
        "trade_id" => venue_trade_id,
        "price" => "5556.91",
        "qty" => "5",
        "instrument_id" => "BTC-USD-190628",
        "timestamp" => "2019-05-06T07:19:37.496Z"
      }
    ]

    :my_venue
    |> ProcessMessages.to_name()
    |> GenServer.cast({%{"table" => "futures/trade", "data" => venue_trades}, :ignore})

    assert_event(%Events.Trade{venue_trade_id: venue_trade_id})
  end
end
