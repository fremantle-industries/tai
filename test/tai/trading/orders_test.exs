defmodule Tai.Trading.OrdersTest do
  use ExUnit.Case
  doctest Tai.Trading.Orders

  alias Tai.Trading.{Orders}

  setup do
    Orders.clear()

    :ok
  end

  test "count returns the number of orders" do
    assert Orders.count() == 0

    Orders.add({:my_test_exchange, :btcusd, 100.0, 1.0})

    assert Orders.count() == 1
  end

  test "add can take a single submission" do
    assert Orders.count() == 0

    [order] = Orders.add({:my_test_exchange, :btcusd, 100.0, 1.0})

    assert Orders.count() == 1
    assert {:ok, _} = UUID.info(order.client_id)
    assert order.exchange == :my_test_exchange
    assert order.symbol == :btcusd
    assert order.price == 100.0
    assert order.size == 1.0
    assert %DateTime{} = order.enqueued_at
  end

  test "add can take multiple submissions" do
    assert Orders.count() == 0

    [order_1, order_2] = Orders.add([
      {:my_test_exchange, :btcusd, 100.0, 1.0},
      {:my_test_exchange, :ltcusd, -10.0, 1.1}
    ])

    assert Orders.count() == 2

    assert {:ok, _} = UUID.info(order_1.client_id)
    assert order_1.exchange == :my_test_exchange
    assert order_1.symbol == :btcusd
    assert order_1.price == 100.0
    assert order_1.size == 1.0
    assert %DateTime{} = order_1.enqueued_at

    assert {:ok, _} = UUID.info(order_2.client_id)
    assert order_2.exchange == :my_test_exchange
    assert order_2.symbol == :ltcusd
    assert order_2.price == -10.0
    assert order_2.size == 1.1
    assert order_1.enqueued_at != nil
    assert %DateTime{} = order_2.enqueued_at
  end

  test "get returns the order by client_id" do
    [order] = Orders.add({:my_test_exchange, :btcusd, 100.0, 1.0})

    assert Orders.get(order.client_id) == order
  end

  test "get returns nil when the order doesn't exist" do
    assert Orders.get("i_dont_exist") == nil
  end

  test "update can change the whitelist of attributes" do
    [order] = Orders.add({:my_test_exchange, :btcusd, 100.0, 1.0})

    updated_order = Orders.update(
      order.client_id,
      client_id: "should_not_replace_client_id",
      server_id: "the_server_id",
      created_at: created_at = Timex.now
    )

    assert updated_order.server_id == "the_server_id"
    assert updated_order.created_at == created_at
    assert updated_order.client_id != "should_not_replace_client_id"
    assert Orders.get(order.client_id) == updated_order
  end
end
