defmodule Tai.Trading.OrdersTest do
  use ExUnit.Case
  doctest Tai.Trading.Orders

  alias Tai.Trading.{Order, Orders, OrderStatus, OrderSubmission}

  setup do
    on_exit(fn ->
      Orders.clear()
    end)

    :ok
  end

  test "count returns the total number of orders" do
    assert Orders.count() == 0

    Orders.add(OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 1.0))

    assert Orders.count() == 1
  end

  test "count can filter by status" do
    assert Orders.count(status: OrderStatus.enqueued()) == 0
    assert Orders.count(status: OrderStatus.pending()) == 0

    Orders.add(OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 1.0))

    assert Orders.count(status: OrderStatus.enqueued()) == 1
    assert Orders.count(status: OrderStatus.pending()) == 0
  end

  test "add can take a single submission" do
    assert Orders.count() == 0

    [order] = Orders.add(OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 1.0))

    assert Orders.count() == 1
    assert {:ok, _} = UUID.info(order.client_id)
    assert order.exchange == :my_test_exchange
    assert order.symbol == :btcusd
    assert order.price == 100.0
    assert order.size == 1.0
    assert order.status == OrderStatus.enqueued()
    assert order.side == Order.buy()
    assert order.type == Order.limit()
    assert %DateTime{} = order.enqueued_at
  end

  test "add can take multiple submissions" do
    assert Orders.count() == 0

    [order_1, order_2] =
      Orders.add([
        OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 1.0),
        OrderSubmission.sell_limit(:my_test_exchange, :ltcusd, 10.0, 1.1)
      ])

    assert Orders.count() == 2

    assert {:ok, _} = UUID.info(order_1.client_id)
    assert order_1.exchange == :my_test_exchange
    assert order_1.symbol == :btcusd
    assert order_1.side == Order.buy()
    assert order_1.type == Order.limit()
    assert order_1.price == 100.0
    assert order_1.size == 1.0
    assert order_1.status == OrderStatus.enqueued()
    assert %DateTime{} = order_1.enqueued_at

    assert {:ok, _} = UUID.info(order_2.client_id)
    assert order_2.exchange == :my_test_exchange
    assert order_2.symbol == :ltcusd
    assert order_2.side == Order.sell()
    assert order_2.type == Order.limit()
    assert order_2.price == 10.0
    assert order_2.size == 1.1
    assert order_2.status == OrderStatus.enqueued()
    assert %DateTime{} = order_2.enqueued_at
  end

  test "add can take an empty list" do
    assert Orders.count() == 0

    [] = Orders.add([])

    assert Orders.count() == 0
  end

  test "find returns the order by client_id" do
    [order] = Orders.add(OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 1.0))

    assert Orders.find(order.client_id) == order
  end

  test "find returns nil when the client_id doesn't exist" do
    assert Orders.find("client_id_doesnt_exist") == nil
  end

  test "update can change the whitelist of attributes" do
    [order] = Orders.add(OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 1.0))

    updated_order =
      Orders.update(
        order.client_id,
        client_id: "should_not_replace_client_id",
        server_id: "the_server_id",
        created_at: created_at = Timex.now(),
        status: OrderStatus.pending()
      )

    assert updated_order.server_id == "the_server_id"
    assert updated_order.created_at == created_at
    assert updated_order.status == OrderStatus.pending()
    assert updated_order.client_id != "should_not_replace_client_id"
    assert Orders.find(order.client_id) == updated_order
  end

  test "all returns a list of current orders" do
    assert Orders.all() == []

    [order] = Orders.add(OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 1.0))

    assert Orders.all() == [order]
  end

  test "where can filter by a singular client_id" do
    [_order_1, order_2, _order_3] =
      Orders.add([
        OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 0.1),
        OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 1.0),
        OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 2.0)
      ])

    assert Orders.where(client_id: order_2.client_id) == [order_2]
    assert Orders.where(client_id: "client_id_does_not_exist") == []
  end

  test "where can filter by multiple client_ids" do
    [_order_1, order_2, order_3] =
      Orders.add([
        OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 0.1),
        OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 1.0),
        OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 2.0)
      ])

    found_orders =
      [client_id: [order_2.client_id, order_3.client_id]]
      |> Orders.where()
      |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

    assert found_orders == [order_2, order_3]
    assert Orders.where(client_id: []) == []
    assert Orders.where(client_id: ["client_id_does_not_exist"]) == []
  end

  test "where can filter by a single status" do
    [order_1, order_2] =
      Orders.add([
        OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 0.1),
        OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 1.0)
      ])

    found_orders =
      [status: OrderStatus.enqueued()]
      |> Orders.where()
      |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

    assert found_orders == [order_1, order_2]
    assert Orders.where(status: OrderStatus.pending()) == []
    assert Orders.where(status: :status_does_not_exist) == []
  end

  test "where can filter by multiple status'" do
    [order_1, order_2, order_3] =
      Orders.add([
        OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 0.1),
        OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 1.0),
        OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 1.0)
      ])

    order_2 = Orders.update(order_2.client_id, status: OrderStatus.pending())
    Orders.update(order_3.client_id, status: OrderStatus.error())

    found_orders =
      [status: [OrderStatus.enqueued(), OrderStatus.pending()]]
      |> Orders.where()
      |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

    assert found_orders == [order_1, order_2]
    assert Orders.where(status: []) == []
    assert Orders.where(status: [:status_does_not_exist]) == []
  end

  test "where can filter by client_ids and status" do
    [_order_1, order_2, order_3] =
      Orders.add([
        OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 0.1),
        OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 1.0),
        OrderSubmission.buy_limit(:my_test_exchange, :btcusd, 100.0, 2.0)
      ])

    order_2 = Orders.update(order_2.client_id, status: OrderStatus.error())
    order_3 = Orders.update(order_3.client_id, status: OrderStatus.error())

    error_orders =
      [
        client_id: [order_2.client_id, order_3.client_id],
        status: OrderStatus.error()
      ]
      |> Orders.where()
      |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

    assert error_orders == [order_2, order_3]
  end
end
