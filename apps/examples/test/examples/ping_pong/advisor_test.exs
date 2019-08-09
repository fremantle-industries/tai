defmodule Examples.PingPong.AdvisorTest do
  use Tai.TestSupport.E2ECase, async: false
  alias Tai.Events.OrderUpdated

  @scenario :ping_pong
  @venue :test_exchange_a
  @product :btc_usd

  def before_app_start, do: seed_mock_responses(@scenario)

  def after_app_start do
    configure_advisor_group(@scenario)
    start_advisors(where: [group_id: @scenario])
  end

  test "create a passive buy entry order and flip it to a passive sell order upon fill" do
    push_stream_market_data({@scenario, :snapshot, @venue, @product})

    assert_event(%OrderUpdated{side: :buy, status: :open} = open_entry)
    assert open_entry.price == Decimal.new("5500.5")
    assert open_entry.qty == Decimal.new(10)

    push_stream_market_data({@scenario, :change_1, @venue, @product})

    assert_event(%OrderUpdated{side: :buy, status: :canceled})

    assert_event(%OrderUpdated{side: :buy, status: :open} = new_open_entry)
    assert new_open_entry.price == Decimal.new("5504.0")
    assert new_open_entry.qty == Decimal.new(10)

    push_stream_order_update(
      {@scenario, :order_update_filled, @venue, @product},
      new_open_entry.client_id
    )

    assert_event(%OrderUpdated{side: :buy, status: :filled} = filled_entry)
    assert filled_entry.cumulative_qty == Decimal.new(10)
    assert filled_entry.leaves_qty == Decimal.new(0)
    assert filled_entry.qty == Decimal.new(10)

    assert_event(%OrderUpdated{side: :sell, status: :open} = open_exit)
    assert open_exit.price == Decimal.new("5504.5")
    assert open_exit.qty == Decimal.new(10)
  end
end
