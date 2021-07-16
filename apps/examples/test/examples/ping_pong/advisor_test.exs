defmodule Examples.PingPong.AdvisorTest do
  use Tai.TestSupport.E2ECase, async: false

  alias Tai.Orders.{
    OrderRepo,
    Order,
    Transitions
  }

  @scenario :ping_pong
  @venue :test_exchange_a
  @product :btc_usd

  def before_start_app, do: seed_mock_responses(@scenario)

  def after_start_app, do: seed_venues(@scenario)

  def after_boot_app do
    start_venue(@venue)
    configure_advisor_group(@scenario)
    start_advisors(where: [group_id: @scenario])
  end

  test "create a passive buy entry order and flip it to a passive sell order upon fill" do
    # create an entry maker limit order on the first quote
    push_stream_market_data({@scenario, :snapshot, @venue, @product})

    assert_receive {:order_updated, entry_order_1_client_id, %Transitions.AcceptCreate{}}
    entry_order_1 = OrderRepo.get!(Order, entry_order_1_client_id)
    assert entry_order_1.side == :buy
    assert entry_order_1.status == :create_accepted
    assert entry_order_1.price == Decimal.new("5500.5")
    assert entry_order_1.qty == Decimal.new(10)
    assert entry_order_1.leaves_qty == Decimal.new(10)

    push_stream_order_update(
      {@scenario, :entry_order_1_open, @venue, @product},
      entry_order_1_client_id
    )

    assert_receive {:order_updated, ^entry_order_1_client_id, %Transitions.Open{}}
    open_entry_order_1 = OrderRepo.get!(Order, entry_order_1_client_id)
    assert open_entry_order_1.status == :open
    assert open_entry_order_1.qty == Decimal.new(10)
    assert open_entry_order_1.leaves_qty == Decimal.new(10)

    # cancel and replace the entry order when the inside quote changes
    push_stream_market_data({@scenario, :change_1, @venue, @product})
    assert_receive {:order_updated, ^entry_order_1_client_id, %Transitions.AcceptCancel{}}

    push_stream_order_update(
      {@scenario, :entry_order_1_cancel, @venue, @product},
      entry_order_1_client_id
    )

    assert_receive {:order_updated, ^entry_order_1_client_id, %Transitions.Cancel{}}

    assert_receive {:order_updated, order_2_client_id, %Transitions.AcceptCreate{}}
    order_2 = OrderRepo.get!(Order, order_2_client_id)
    assert order_2.side == :buy
    assert order_2.status == :create_accepted
    assert order_2.price == Decimal.new("5504")
    assert order_2.qty == Decimal.new(10)

    push_stream_order_update(
      {@scenario, :entry_order_2_open, @venue, @product},
      order_2_client_id
    )

    assert_receive {:order_updated, ^order_2_client_id, %Transitions.Open{}}

    # create an exit maker limit order when the entry is filled
    push_stream_order_update(
      {@scenario, :order_update_filled, @venue, @product},
      order_2_client_id
    )

    assert_receive {:order_updated, ^order_2_client_id, %Transitions.Fill{}}
    filled_entry_order = OrderRepo.get!(Order, order_2_client_id)
    assert filled_entry_order.status == :filled
    assert filled_entry_order.cumulative_qty == Decimal.new(10)
    assert filled_entry_order.qty == Decimal.new(10)
    assert filled_entry_order.leaves_qty == Decimal.new(0)

    assert_receive {:order_updated, exit_order_1_client_id, %Transitions.AcceptCreate{}}
    exit_order_1 = OrderRepo.get!(Order, exit_order_1_client_id)
    assert exit_order_1.side == :sell
    assert exit_order_1.status == :create_accepted
    assert exit_order_1.price == Decimal.new("5504.5")
    assert exit_order_1.qty == Decimal.new(10)
    assert exit_order_1.leaves_qty == Decimal.new(10)

    # clean up unfilled entry/exit orders when the advisor shuts down
    stop_advisors(where: [group_id: @scenario])
    assert_receive {:order_updated, ^exit_order_1_client_id, %Transitions.AcceptCancel{}}
  end
end
