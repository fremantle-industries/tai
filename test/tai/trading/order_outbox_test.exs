defmodule Tai.Trading.OrderOutboxTest do
  use ExUnit.Case
  doctest Tai.Trading.OrderOutbox

  alias Tai.Trading.{
    Order,
    Orders,
    OrderOutbox,
    OrderResponses,
    OrderStatus,
    OrderSubmission,
    TimeInForce
  }

  defmodule OrderLifecycleSubscriber do
    use GenServer

    def start_link(_) do
      GenServer.start_link(__MODULE__, :ok)
    end

    def init(state) do
      Tai.PubSub.subscribe(:my_test_account)

      {:ok, state}
    end

    def handle_info({:order_enqueued, _order} = msg, state) do
      send(:test, msg)
      {:noreply, state}
    end

    def handle_info({:order_create_ok, _order} = msg, state) do
      send(:test, msg)
      {:noreply, state}
    end

    def handle_info({:order_create_error, _reason, _order} = msg, state) do
      send(:test, msg)
      {:noreply, state}
    end

    def handle_info({:order_cancelling, _order} = msg, state) do
      send(:test, msg)
      {:noreply, state}
    end

    def handle_info({:order_cancelled, _order} = msg, state) do
      send(:test, msg)
      {:noreply, state}
    end
  end

  setup do
    Process.register(self(), :test)
    start_supervised!({Tai.ExchangeAdapters.Test.Account, :my_test_account})
    start_supervised!(OrderLifecycleSubscriber)

    on_exit(fn ->
      Orders.clear()
    end)

    :ok
  end

  test "add enqueues the submissions as orders and then executes it on the exchange" do
    assert Orders.count() == 0

    [new_buy_limit_order, new_sell_limit_order] =
      new_orders =
      OrderOutbox.add([
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd_success,
          100.0,
          0.1,
          TimeInForce.fill_or_kill()
        ),
        OrderSubmission.sell_limit(
          :my_test_account,
          :btcusd_success,
          100.0,
          0.1,
          TimeInForce.fill_or_kill()
        )
      ])

    assert Enum.count(new_orders) == 2
    assert Orders.count() == 2

    assert_receive {:order_enqueued, enqueued_order_1}
    assert enqueued_order_1.client_id == new_buy_limit_order.client_id
    assert enqueued_order_1.status == OrderStatus.enqueued()
    assert enqueued_order_1.side == Order.buy()
    assert enqueued_order_1.time_in_force == TimeInForce.fill_or_kill()
    assert enqueued_order_1.type == Order.limit()
    assert enqueued_order_1.enqueued_at == new_buy_limit_order.enqueued_at
    assert enqueued_order_1.server_id == nil
    assert enqueued_order_1.created_at == nil

    assert_receive {:order_enqueued, enqueued_order_2}
    assert enqueued_order_2.client_id == new_sell_limit_order.client_id
    assert enqueued_order_2.status == OrderStatus.enqueued()
    assert enqueued_order_2.side == Order.sell()
    assert enqueued_order_2.time_in_force == TimeInForce.fill_or_kill()
    assert enqueued_order_2.type == Order.limit()
    assert enqueued_order_2.enqueued_at == new_sell_limit_order.enqueued_at
    assert enqueued_order_2.server_id == nil
    assert enqueued_order_2.created_at == nil

    assert_receive {:order_create_ok, created_order_a}
    assert_receive {:order_create_ok, created_order_b}

    [created_order_1, created_order_2] =
      [created_order_a, created_order_b]
      |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

    assert created_order_1.client_id == new_buy_limit_order.client_id
    assert created_order_1.status == OrderStatus.pending()
    assert created_order_1.side == Order.buy()
    assert created_order_1.time_in_force == TimeInForce.fill_or_kill()
    assert created_order_1.type == Order.limit()
    assert created_order_1.enqueued_at == new_buy_limit_order.enqueued_at
    assert created_order_1.server_id != nil
    assert %DateTime{} = created_order_1.created_at

    assert created_order_2.client_id == new_sell_limit_order.client_id
    assert created_order_2.status == OrderStatus.pending()
    assert created_order_2.side == Order.sell()
    assert created_order_2.time_in_force == TimeInForce.fill_or_kill()
    assert created_order_2.type == Order.limit()
    assert created_order_2.enqueued_at == new_sell_limit_order.enqueued_at
    assert created_order_2.server_id != nil
    assert %DateTime{} = created_order_2.created_at
  end

  test "add broadcasts failed orders and updates the status" do
    assert Orders.count() == 0

    [new_order_1, new_order_2] =
      OrderOutbox.add([
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd_insufficient_funds,
          100.0,
          0.1,
          TimeInForce.fill_or_kill()
        ),
        OrderSubmission.sell_limit(
          :my_test_account,
          :btcusd_insufficient_funds,
          100.0,
          0.1,
          TimeInForce.fill_or_kill()
        )
      ])

    assert Orders.count() == 2
    assert_receive {:order_enqueued, enqueued_order_1}
    assert enqueued_order_1.client_id == new_order_1.client_id
    assert enqueued_order_1.status == OrderStatus.enqueued()

    assert_receive {:order_create_error, error_reason_a, error_order_a}
    assert_receive {:order_create_error, error_reason_b, error_order_b}

    unsorted_errors = [{error_reason_a, error_order_a}, {error_reason_b, error_order_b}]

    [
      {error_reason_1, error_order_1},
      {error_reason_2, error_order_2}
    ] =
      unsorted_errors
      |> Enum.sort(fn {_ra, oa}, {_rb, ob} ->
        DateTime.compare(oa.enqueued_at, ob.enqueued_at) == :lt
      end)

    assert %OrderResponses.InsufficientFunds{} = error_reason_1
    assert error_order_1.client_id == new_order_1.client_id
    assert error_order_1.side == Order.buy()
    assert error_order_1.type == Order.limit()
    assert error_order_1.time_in_force == TimeInForce.fill_or_kill()
    assert error_order_1.status == OrderStatus.error()

    assert %OrderResponses.InsufficientFunds{} = error_reason_2
    assert error_order_2.client_id == new_order_2.client_id
    assert error_order_2.side == Order.sell()
    assert error_order_2.type == Order.limit()
    assert error_order_2.time_in_force == TimeInForce.fill_or_kill()
    assert error_order_2.status == OrderStatus.error()
  end

  test "cancel changes the given pending orders to cancelling and sends the request to the exchange in the background" do
    [order_1, order_2, order_3] =
      OrderOutbox.add([
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd_success,
          100.0,
          0.1,
          TimeInForce.fill_or_kill()
        ),
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd_success,
          100.0,
          1.1,
          TimeInForce.fill_or_kill()
        ),
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd_insufficient_funds,
          100.0,
          2.1,
          TimeInForce.fill_or_kill()
        )
      ])

    assert_receive {:order_enqueued, ^order_1}
    assert_receive {:order_enqueued, ^order_2}
    assert_receive {:order_enqueued, ^order_3}
    assert_receive {:order_create_ok, _}
    assert_receive {:order_create_ok, _}
    assert_receive {:order_create_error, _, _}

    [cancelling_order_1, cancelling_order_2] =
      OrderOutbox.cancel([
        order_1.client_id,
        order_2.client_id,
        order_3.client_id,
        "client_id_doesnt_exist"
      ])
      |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

    assert cancelling_order_1.client_id == order_1.client_id
    assert cancelling_order_1.status == OrderStatus.cancelling()
    assert cancelling_order_2.client_id == order_2.client_id
    assert cancelling_order_2.status == OrderStatus.cancelling()

    assert_receive {:order_cancelling, ^cancelling_order_1}
    assert_receive {:order_cancelling, ^cancelling_order_2}

    assert_receive {:order_cancelled, cancelled_order_1}
    assert_receive {:order_cancelled, cancelled_order_2}

    cancelled_order_client_ids = [cancelled_order_1.client_id, cancelled_order_2.client_id]
    assert cancelled_order_client_ids |> Enum.member?(cancelling_order_1.client_id)
    assert cancelled_order_1.status == OrderStatus.cancelled()
    assert cancelled_order_client_ids |> Enum.member?(cancelling_order_2.client_id)
    assert cancelled_order_2.status == OrderStatus.cancelled()
  end
end
