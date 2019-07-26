defmodule Examples.LogSpread.AdvisorTest do
  use Tai.TestSupport.E2ECase, async: false

  @scenario :log_spread

  def before_app_start, do: seed_mock_responses(@scenario)

  def after_app_start do
    configure_advisor_group(@scenario)
    start_advisors(where: [group_id: @scenario])
  end

  test "logs the bid/ask spread via a custom event" do
    push_stream_market_data({@scenario, :snapshot, :test_exchange_a, :btc_usd})

    assert_receive {Tai.Event, %Examples.LogSpread.Events.Spread{} = event, _}
    assert event.venue_id == :test_exchange_a
    assert event.product_symbol == :btc_usd
    assert event.bid_price == "6500.1"
    assert event.ask_price == "6500.11"
    assert event.spread == "0.01"
  end
end
