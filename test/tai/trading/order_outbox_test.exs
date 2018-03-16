defmodule Tai.Trading.OrderOutboxTest do
  use ExUnit.Case
  doctest Tai.Trading.OrderOutbox

  alias Tai.Trading.{OrderOutbox, Orders, OrderResponses, OrderStatus}

  defmodule OrderLifecycleSubscriber do
    use GenServer

    def start_link(_) do
      GenServer.start_link(__MODULE__, :ok)
    end

    def init(state) do
      Tai.PubSub.subscribe([
        :order_enqueued,
        :order_create_ok,
        :order_create_error,
        :order_cancelling,
        :order_cancelled
      ])

      {:ok, state}
    end

    def handle_info({:order_enqueued, _order} = msg, state) do
      send :test, msg
      {:noreply, state}
    end

    def handle_info({:order_create_ok, _order} = msg, state) do
      send :test, msg
      {:noreply, state}
    end

    def handle_info({:order_create_error, _reason, _order} = msg, state) do
      send :test, msg
      {:noreply, state}
    end

    def handle_info({:order_cancelling, _order} = msg, state) do
      send :test, msg
      {:noreply, state}
    end

    def handle_info({:order_cancelled, _order} = msg, state) do
      send :test, msg
      {:noreply, state}
    end
  end

  setup do
    Process.register self(), :test
    start_supervised!({Tai.ExchangeAdapters.Test.Account, :my_test_exchange})
    start_supervised!(OrderLifecycleSubscriber)

    on_exit fn ->
      Orders.clear()
    end

    :ok
  end

  test "add converts the submission into an order then broadcasts it to be sent to the exchange in the background" do
    assert Orders.count() == 0

    [new_order] = new_orders = OrderOutbox.add({:my_test_exchange, :btcusd_success, 100.0, 0.1})

    assert Enum.count(new_orders) == 1
    assert Orders.count() == 1
    assert_receive {:order_enqueued, enqueued_order}
    assert enqueued_order.client_id == new_order.client_id
    assert enqueued_order.enqueued_at == new_order.enqueued_at
    assert enqueued_order.server_id == nil
    assert enqueued_order.created_at == nil
    assert enqueued_order.status == OrderStatus.enqueued

    assert_receive {:order_create_ok, created_order}
    assert created_order.client_id == new_order.client_id
    assert created_order.enqueued_at == new_order.enqueued_at
    assert created_order.server_id != nil
    assert %DateTime{} = created_order.created_at
    assert created_order.status == OrderStatus.pending
  end

  test "add broadcasts failed orders and updates the status" do
    assert Orders.count() == 0

    [new_order] = new_orders = OrderOutbox.add({:my_test_exchange, :btcusd_insufficient_funds, 100.0, 0.1})

    assert Enum.count(new_orders) == 1
    assert Orders.count() == 1
    assert_receive {:order_enqueued, enqueued_order}
    assert enqueued_order.client_id == new_order.client_id
    assert enqueued_order.status == OrderStatus.enqueued

    assert_receive {:order_create_error, error_reason, error_order}
    assert %OrderResponses.InsufficientFunds{} = error_reason
    assert error_order.client_id == new_order.client_id
    assert error_order.status == OrderStatus.error
  end

  test "cancel changes the given pending orders to cancelling and sends the request to the exchange in the background" do
    [order_1, order_2, order_3] = OrderOutbox.add([
      {:my_test_exchange, :btcusd_success, 100.0, 0.1},
      {:my_test_exchange, :btcusd_success, 100.0, 1.1},
      {:my_test_exchange, :btcusd_insufficient_funds, 100.0, 2.1}
    ])

    assert_receive {:order_enqueued, ^order_1}
    assert_receive {:order_enqueued, ^order_2}
    assert_receive {:order_enqueued, ^order_3}
    assert_receive {:order_create_ok, _}
    assert_receive {:order_create_ok, _}
    assert_receive {:order_create_error, _, _}

    [cancelling_order_1, cancelling_order_2] = OrderOutbox.cancel([
      order_1.client_id,
      order_2.client_id,
      order_3.client_id,
      "client_id_doesnt_exist"
    ])
    |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

    assert cancelling_order_1.client_id == order_1.client_id
    assert cancelling_order_1.status == OrderStatus.cancelling
    assert cancelling_order_2.client_id == order_2.client_id
    assert cancelling_order_2.status == OrderStatus.cancelling

    assert_receive {:order_cancelling, ^cancelling_order_1}
    assert_receive {:order_cancelling, ^cancelling_order_2}

    assert_receive {:order_cancelled, cancelled_order_1}
    assert_receive {:order_cancelled, cancelled_order_2}

    cancelled_order_client_ids = [cancelled_order_1.client_id, cancelled_order_2.client_id]
    assert cancelled_order_client_ids |> Enum.member?(cancelling_order_1.client_id)
    assert cancelled_order_1.status == OrderStatus.cancelled
    assert cancelled_order_client_ids |> Enum.member?(cancelling_order_2.client_id)
    assert cancelled_order_2.status == OrderStatus.cancelled
  end
end
