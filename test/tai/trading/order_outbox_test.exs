defmodule Tai.Trading.OrderOutboxTest do
  use ExUnit.Case
  doctest Tai.Trading.OrderOutbox

  alias Tai.Trading.{OrderOutbox, Orders, OrderResponses}

  defmodule OrderEnqueuedSubscriber do
    use GenServer

    def start_link(_) do
      GenServer.start_link(__MODULE__, :ok)
    end

    def init(:ok) do
      Tai.PubSub.subscribe(:order_enqueued)
      Tai.PubSub.subscribe(:order_create_ok)
      Tai.PubSub.subscribe(:order_create_error)
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
  end

  setup do
    Process.register self(), :test
    Orders.clear()
    start_supervised!({Tai.ExchangeAdapters.Test.Account, :my_test_exchange})
    start_supervised!(OrderEnqueuedSubscriber)

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

    assert_receive {:order_create_ok, created_order}
    assert created_order.client_id == new_order.client_id
    assert created_order.enqueued_at == new_order.enqueued_at
    assert created_order.server_id != nil
    assert created_order.created_at != nil
  end

  test "add broadcasts failed orders" do
    assert Orders.count() == 0

    [new_order] = new_orders = OrderOutbox.add({:my_test_exchange, :btcusd_insufficient_funds, 100.0, 0.1})

    assert Enum.count(new_orders) == 1
    assert Orders.count() == 1
    assert_receive {:order_enqueued, enqueued_order}
    assert enqueued_order.client_id == new_order.client_id

    assert_receive {:order_create_error, error_reason, error_order}
    assert %OrderResponses.InsufficientFunds{} = error_reason
    assert error_order.client_id == new_order.client_id
  end
end
