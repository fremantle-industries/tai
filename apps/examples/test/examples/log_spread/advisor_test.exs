defmodule Examples.LogSpread.AdvisorTest do
  use Tai.TestSupport.E2ECase, async: false

  @scenario :log_spread
  @venue :test_exchange_a
  @product :btc_usd

  def before_start_app, do: seed_mock_responses(@scenario)

  def after_start_app, do: seed_venues(@scenario)

  def after_boot_app do
    start_venue(@venue)
    configure_advisor_group(@scenario)
    start_advisors(where: [group_id: @scenario])
  end

  test "logs the bid/ask spread via a custom event" do
    push_stream_market_data({@scenario, :snapshot, @venue, @product})

    assert_receive {TaiEvents.Event, %Examples.LogSpread.Events.Spread{} = event, _}
    assert event.venue_id == @venue
    assert event.product_symbol == @product
    assert event.bid_price == Decimal.new("6500.1")
    assert event.ask_price == Decimal.new("6500.11")
    assert event.spread == Decimal.new("0.01")
  end
end
