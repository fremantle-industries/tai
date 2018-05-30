defmodule Tai.Trading.OrderStoreTest do
  use ExUnit.Case
  doctest Tai.Trading.OrderStore

  alias Tai.Trading.{Order, OrderStatus, OrderSubmission, TimeInForce}

  setup do
    on_exit(fn ->
      Tai.Trading.OrderStore.clear()
    end)

    :ok
  end

  test "count returns the total number of orders" do
    assert Tai.Trading.OrderStore.count() == 0

    Tai.Trading.OrderStore.add(
      OrderSubmission.buy_limit(:my_test_account, :btcusd, 100.0, 1.0, TimeInForce.fill_or_kill())
    )

    assert Tai.Trading.OrderStore.count() == 1
  end

  test "count can filter by status" do
    assert Tai.Trading.OrderStore.count(status: OrderStatus.enqueued()) == 0
    assert Tai.Trading.OrderStore.count(status: OrderStatus.pending()) == 0

    Tai.Trading.OrderStore.add(
      OrderSubmission.buy_limit(:my_test_account, :btcusd, 100.0, 1.0, TimeInForce.fill_or_kill())
    )

    assert Tai.Trading.OrderStore.count(status: OrderStatus.enqueued()) == 1
    assert Tai.Trading.OrderStore.count(status: OrderStatus.pending()) == 0
  end

  test "add can take a single submission" do
    assert Tai.Trading.OrderStore.count() == 0

    [order] =
      Tai.Trading.OrderStore.add(
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          1.0,
          TimeInForce.fill_or_kill()
        )
      )

    assert Tai.Trading.OrderStore.count() == 1
    assert {:ok, _} = UUID.info(order.client_id)
    assert order.account_id == :my_test_account
    assert order.symbol == :btcusd
    assert order.price == 100.0
    assert order.size == 1.0
    assert order.status == OrderStatus.enqueued()
    assert order.side == Order.buy()
    assert order.type == Order.limit()
    assert %DateTime{} = order.enqueued_at
  end

  test "add can take multiple submissions" do
    assert Tai.Trading.OrderStore.count() == 0

    [order_1, order_2] =
      Tai.Trading.OrderStore.add([
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          1.0,
          TimeInForce.fill_or_kill()
        ),
        OrderSubmission.sell_limit(
          :my_test_account,
          :ltcusd,
          10.0,
          1.1,
          TimeInForce.fill_or_kill()
        )
      ])

    assert Tai.Trading.OrderStore.count() == 2

    assert {:ok, _} = UUID.info(order_1.client_id)
    assert order_1.account_id == :my_test_account
    assert order_1.symbol == :btcusd
    assert order_1.side == Order.buy()
    assert order_1.type == Order.limit()
    assert order_1.time_in_force == TimeInForce.fill_or_kill()
    assert order_1.price == 100.0
    assert order_1.size == 1.0
    assert order_1.status == OrderStatus.enqueued()
    assert %DateTime{} = order_1.enqueued_at

    assert {:ok, _} = UUID.info(order_2.client_id)
    assert order_2.account_id == :my_test_account
    assert order_2.symbol == :ltcusd
    assert order_2.side == Order.sell()
    assert order_2.type == Order.limit()
    assert order_2.time_in_force == TimeInForce.fill_or_kill()
    assert order_2.price == 10.0
    assert order_2.size == 1.1
    assert order_2.status == OrderStatus.enqueued()
    assert %DateTime{} = order_2.enqueued_at
  end

  test "add can take an empty list" do
    assert Tai.Trading.OrderStore.count() == 0

    [] = Tai.Trading.OrderStore.add([])

    assert Tai.Trading.OrderStore.count() == 0
  end

  test "find returns the order by client_id" do
    [order] =
      Tai.Trading.OrderStore.add(
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          1.0,
          TimeInForce.fill_or_kill()
        )
      )

    assert Tai.Trading.OrderStore.find(order.client_id) == order
  end

  test "find returns nil when the client_id doesn't exist" do
    assert Tai.Trading.OrderStore.find("client_id_doesnt_exist") == nil
  end

  test "update can change the whitelist of attributes" do
    [order] =
      Tai.Trading.OrderStore.add(
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          1.0,
          TimeInForce.fill_or_kill()
        )
      )

    updated_order =
      Tai.Trading.OrderStore.update(
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
    assert Tai.Trading.OrderStore.find(order.client_id) == updated_order
  end

  test "all returns a list of current orders" do
    assert Tai.Trading.OrderStore.all() == []

    [order] =
      Tai.Trading.OrderStore.add(
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          1.0,
          TimeInForce.fill_or_kill()
        )
      )

    assert Tai.Trading.OrderStore.all() == [order]
  end

  test "where can filter by a singular client_id" do
    [_order_1, order_2, _order_3] =
      Tai.Trading.OrderStore.add([
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          0.1,
          TimeInForce.fill_or_kill()
        ),
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          1.0,
          TimeInForce.fill_or_kill()
        ),
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          2.0,
          TimeInForce.fill_or_kill()
        )
      ])

    assert Tai.Trading.OrderStore.where(client_id: order_2.client_id) == [order_2]
    assert Tai.Trading.OrderStore.where(client_id: "client_id_does_not_exist") == []
  end

  test "where can filter by multiple client_ids" do
    [_order_1, order_2, order_3] =
      Tai.Trading.OrderStore.add([
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          0.1,
          TimeInForce.fill_or_kill()
        ),
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          1.0,
          TimeInForce.fill_or_kill()
        ),
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          2.0,
          TimeInForce.fill_or_kill()
        )
      ])

    found_orders =
      [client_id: [order_2.client_id, order_3.client_id]]
      |> Tai.Trading.OrderStore.where()
      |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

    assert found_orders == [order_2, order_3]
    assert Tai.Trading.OrderStore.where(client_id: []) == []
    assert Tai.Trading.OrderStore.where(client_id: ["client_id_does_not_exist"]) == []
  end

  test "where can filter by a single status" do
    [order_1, order_2] =
      Tai.Trading.OrderStore.add([
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          0.1,
          TimeInForce.fill_or_kill()
        ),
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          1.0,
          TimeInForce.fill_or_kill()
        )
      ])

    found_orders =
      [status: OrderStatus.enqueued()]
      |> Tai.Trading.OrderStore.where()
      |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

    assert found_orders == [order_1, order_2]
    assert Tai.Trading.OrderStore.where(status: OrderStatus.pending()) == []
    assert Tai.Trading.OrderStore.where(status: :status_does_not_exist) == []
  end

  test "where can filter by multiple status'" do
    [order_1, order_2, order_3] =
      Tai.Trading.OrderStore.add([
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          0.1,
          TimeInForce.fill_or_kill()
        ),
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          1.0,
          TimeInForce.fill_or_kill()
        ),
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          1.0,
          TimeInForce.fill_or_kill()
        )
      ])

    order_2 = Tai.Trading.OrderStore.update(order_2.client_id, status: OrderStatus.pending())
    Tai.Trading.OrderStore.update(order_3.client_id, status: OrderStatus.error())

    found_orders =
      [status: [OrderStatus.enqueued(), OrderStatus.pending()]]
      |> Tai.Trading.OrderStore.where()
      |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

    assert found_orders == [order_1, order_2]
    assert Tai.Trading.OrderStore.where(status: []) == []
    assert Tai.Trading.OrderStore.where(status: [:status_does_not_exist]) == []
  end

  test "where can filter by client_ids and status" do
    [_order_1, order_2, order_3] =
      Tai.Trading.OrderStore.add([
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          0.1,
          TimeInForce.fill_or_kill()
        ),
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          1.0,
          TimeInForce.fill_or_kill()
        ),
        OrderSubmission.buy_limit(
          :my_test_account,
          :btcusd,
          100.0,
          2.0,
          TimeInForce.fill_or_kill()
        )
      ])

    order_2 = Tai.Trading.OrderStore.update(order_2.client_id, status: OrderStatus.error())
    order_3 = Tai.Trading.OrderStore.update(order_3.client_id, status: OrderStatus.error())

    error_orders =
      [
        client_id: [order_2.client_id, order_3.client_id],
        status: OrderStatus.error()
      ]
      |> Tai.Trading.OrderStore.where()
      |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

    assert error_orders == [order_2, order_3]
  end
end
