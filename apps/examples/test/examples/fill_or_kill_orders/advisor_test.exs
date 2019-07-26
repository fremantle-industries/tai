defmodule Examples.FillOrKillOrders.AdvisorTest do
  use Tai.TestSupport.E2ECase, async: false

  @scenario :fill_or_kill_orders

  def before_app_start, do: seed_mock_responses(@scenario)

  def after_app_start do
    configure_advisor_group(@scenario)
    start_advisors(where: [group_id: @scenario])
  end

  test "creates a single fill or kill order" do
    push_stream_market_data({:fill_or_kill_orders, :snapshot, :test_exchange_a, :btc_usd})

    assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :enqueued} = enqueued_event, _}
    assert enqueued_event.cumulative_qty == Decimal.new(0)

    assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :filled} = filled_event, _}
    assert filled_event.cumulative_qty == Decimal.new("0.1")
  end
end
