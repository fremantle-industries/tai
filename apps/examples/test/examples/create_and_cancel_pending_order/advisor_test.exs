defmodule Examples.CreateAndCancelPendingOrder.AdvisorTest do
  use Tai.TestSupport.E2ECase, async: false

  @scenario :create_and_cancel_pending_order

  def before_app_start, do: seed_mock_responses(@scenario)

  def after_app_start do
    configure_advisor_group(@scenario)
    start_advisors(where: [group_id: @scenario])
  end

  test "creates a single limit order and then cancels it" do
    push_stream_market_data(
      {:create_and_cancel_pending_order, :snapshot, :test_exchange_a, :btc_usd}
    )

    assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :open}, _}
    assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :pending_cancel}, _}
    assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :canceled}, _}
  end
end
