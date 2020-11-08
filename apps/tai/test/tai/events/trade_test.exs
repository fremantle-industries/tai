defmodule Tai.Events.TradeTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms trade to a string" do
    {:ok, received_at, _} = DateTime.from_iso8601("2014-01-23T23:50:07.123+00:00")
    {:ok, timestamp, _} = DateTime.from_iso8601("2020-01-23T23:50:07.123+00:00")
    venue_trade_id = Ecto.UUID.generate()

    event =
      struct!(Tai.Events.Trade, %{
        venue_id: :my_venue,
        symbol: :btc_usd,
        received_at: received_at,
        timestamp: timestamp,
        price: Decimal.new("1000.5"),
        qty:  Decimal.new(5),
        taker_side: :buy,
        venue_trade_id: venue_trade_id
      })

    assert %{} = json = TaiEvents.LogEvent.to_data(event)
    assert json.venue_id == :my_venue
    assert json.symbol == :btc_usd
    assert json.received_at == received_at
    assert json.timestamp == timestamp
    assert json.price == Decimal.new("1000.5")
    assert json.qty == Decimal.new(5)
    assert json.taker_side == :buy
    assert json.venue_trade_id == venue_trade_id
  end
end
