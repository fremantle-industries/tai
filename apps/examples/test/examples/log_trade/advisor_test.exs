defmodule Examples.LogTrade.AdvisorTest do
  use Tai.TestSupport.E2ECase, async: false

  @scenario :log_trade
  @venue :test_exchange_a
  @product :btc_usd

  def before_start_app, do: seed_mock_responses(@scenario)

  def after_start_app, do: seed_venues(@scenario)

  def after_boot_app do
    start_venue(@venue)
    configure_fleet(@scenario)
    start_advisors(where: [fleet_id: @scenario])
  end

  test "log streaming trades via a custom event" do
    push_stream_trade({@scenario, :trade, @venue, @product})

    assert_receive {TaiEvents.Event, %Examples.LogTrade.Events.Trade{} = event, _}
    assert event.id != nil
    assert event.venue == @venue
    assert event.product_symbol == @product
    assert event.price == Decimal.new("100.1")
    assert event.qty == Decimal.new("7.0")
    assert event.side == "buy"
    assert event.liquidation == false
    assert event.received_at != nil
    assert %DateTime{} = event.venue_timestamp
  end
end
