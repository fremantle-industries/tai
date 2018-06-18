defmodule Tai.Trading.OrderStoreTest do
  use ExUnit.Case
  doctest Tai.Trading.OrderStore

  setup do
    on_exit(fn ->
      Tai.Trading.OrderStore.clear()
    end)

    :ok
  end

  defp add_order do
    Tai.Trading.OrderSubmission.buy_limit(
      :my_test_account,
      :btc_usd,
      100.0,
      1.0,
      Tai.Trading.TimeInForce.fill_or_kill()
    )
    |> Tai.Trading.OrderStore.add()
  end

  test "count returns the total number of orders" do
    assert Tai.Trading.OrderStore.count() == 0

    add_order()

    assert Tai.Trading.OrderStore.count() == 1
  end

  test "count can filter by status" do
    assert Tai.Trading.OrderStore.count(status: Tai.Trading.OrderStatus.enqueued()) == 0
    assert Tai.Trading.OrderStore.count(status: Tai.Trading.OrderStatus.pending()) == 0

    add_order()

    assert Tai.Trading.OrderStore.count(status: Tai.Trading.OrderStatus.enqueued()) == 1
    assert Tai.Trading.OrderStore.count(status: Tai.Trading.OrderStatus.pending()) == 0
  end

  describe "#add" do
    test "can take a single submission" do
      assert Tai.Trading.OrderStore.count() == 0

      [order] = add_order()

      assert Tai.Trading.OrderStore.count() == 1
      assert {:ok, _} = UUID.info(order.client_id)
      assert order.account_id == :my_test_account
      assert order.symbol == :btc_usd
      assert order.price == 100.0
      assert order.size == 1.0
      assert order.status == Tai.Trading.OrderStatus.enqueued()
      assert order.side == Tai.Trading.Order.buy()
      assert order.type == Tai.Trading.Order.limit()
      assert %DateTime{} = order.enqueued_at
    end

    test "can take multiple submissions" do
      assert Tai.Trading.OrderStore.count() == 0

      submission_1 =
        Tai.Trading.OrderSubmission.buy_limit(
          :my_test_account,
          :btc_usd,
          100.0,
          1.0,
          Tai.Trading.TimeInForce.fill_or_kill()
        )

      submission_2 =
        Tai.Trading.OrderSubmission.sell_limit(
          :my_test_account,
          :ltc_usd,
          10.0,
          1.1,
          Tai.Trading.TimeInForce.fill_or_kill()
        )

      [order_1, order_2] =
        [submission_1, submission_2]
        |> Tai.Trading.OrderStore.add()

      assert Tai.Trading.OrderStore.count() == 2

      assert {:ok, _} = UUID.info(order_1.client_id)
      assert order_1.account_id == :my_test_account
      assert order_1.symbol == :btc_usd
      assert order_1.side == Tai.Trading.Order.buy()
      assert order_1.type == Tai.Trading.Order.limit()
      assert order_1.time_in_force == Tai.Trading.TimeInForce.fill_or_kill()
      assert order_1.price == 100.0
      assert order_1.size == 1.0
      assert order_1.status == Tai.Trading.OrderStatus.enqueued()
      assert %DateTime{} = order_1.enqueued_at

      assert {:ok, _} = UUID.info(order_2.client_id)
      assert order_2.account_id == :my_test_account
      assert order_2.symbol == :ltc_usd
      assert order_2.side == Tai.Trading.Order.sell()
      assert order_2.type == Tai.Trading.Order.limit()
      assert order_2.time_in_force == Tai.Trading.TimeInForce.fill_or_kill()
      assert order_2.price == 10.0
      assert order_2.size == 1.1
      assert order_2.status == Tai.Trading.OrderStatus.enqueued()
      assert %DateTime{} = order_2.enqueued_at
    end

    test "can take an empty list" do
      assert Tai.Trading.OrderStore.count() == 0

      [] = Tai.Trading.OrderStore.add([])

      assert Tai.Trading.OrderStore.count() == 0
    end
  end

  describe "#find" do
    test "returns the order by client_id" do
      [order] = add_order()

      assert Tai.Trading.OrderStore.find(order.client_id) == order
    end

    test "returns nil when the client_id doesn't exist" do
      assert Tai.Trading.OrderStore.find("client_id_doesnt_exist") == nil
    end
  end

  describe "#find_by_and_update" do
    test "can change the whitelist of attributes" do
      [order] = add_order()

      assert {:ok, [old_order, updated_order]} =
               Tai.Trading.OrderStore.find_by_and_update(
                 [client_id: order.client_id],
                 client_id: "changed_client_id",
                 status: Tai.Trading.OrderStatus.error()
               )

      assert old_order == order
      assert updated_order.status == Tai.Trading.OrderStatus.error()
      assert updated_order.client_id == order.client_id
    end

    test "returns an error tuple when the order can't be found" do
      assert {:error, :not_found} =
               Tai.Trading.OrderStore.find_by_and_update(
                 [client_id: "idontexist"],
                 []
               )
    end

    test "returns an error tuple when multiple orders are found" do
      add_order()
      add_order()

      assert {:error, :multiple_orders_found} =
               Tai.Trading.OrderStore.find_by_and_update(
                 [status: Tai.Trading.OrderStatus.enqueued()],
                 []
               )
    end
  end

  test "all returns a list of current orders" do
    assert Tai.Trading.OrderStore.all() == []

    [order] = add_order()

    assert Tai.Trading.OrderStore.all() == [order]
  end

  describe "#where" do
    test "can filter by a singular client_id" do
      add_order()
      [order_2] = add_order()
      add_order()

      assert Tai.Trading.OrderStore.where(client_id: order_2.client_id) == [order_2]
      assert Tai.Trading.OrderStore.where(client_id: "client_id_does_not_exist") == []
    end

    test "can filter by multiple client_ids" do
      add_order()
      [order_2] = add_order()
      [order_3] = add_order()

      found_orders =
        [client_id: [order_2.client_id, order_3.client_id]]
        |> Tai.Trading.OrderStore.where()
        |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

      assert found_orders == [order_2, order_3]
      assert Tai.Trading.OrderStore.where(client_id: []) == []
      assert Tai.Trading.OrderStore.where(client_id: ["client_id_does_not_exist"]) == []
    end

    test "can filter by a single status" do
      [order_1] = add_order()
      [order_2] = add_order()

      found_orders =
        [status: Tai.Trading.OrderStatus.enqueued()]
        |> Tai.Trading.OrderStore.where()
        |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

      assert found_orders == [order_1, order_2]
      assert Tai.Trading.OrderStore.where(status: Tai.Trading.OrderStatus.pending()) == []
      assert Tai.Trading.OrderStore.where(status: :status_does_not_exist) == []
    end

    test "can filter by multiple status'" do
      [order_1] = add_order()
      [order_2] = add_order()
      [order_3] = add_order()

      {:ok, [_, updated_order_2]} =
        Tai.Trading.OrderStore.find_by_and_update(
          [client_id: order_2.client_id],
          status: Tai.Trading.OrderStatus.pending()
        )

      Tai.Trading.OrderStore.find_by_and_update(
        [client_id: order_3.client_id],
        status: Tai.Trading.OrderStatus.error()
      )

      found_orders =
        [status: [Tai.Trading.OrderStatus.enqueued(), Tai.Trading.OrderStatus.pending()]]
        |> Tai.Trading.OrderStore.where()
        |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

      assert found_orders == [order_1, updated_order_2]
      assert Tai.Trading.OrderStore.where(status: []) == []
      assert Tai.Trading.OrderStore.where(status: [:status_does_not_exist]) == []
    end

    test "can filter by client_ids and status" do
      add_order()
      [order_2] = add_order()
      [order_3] = add_order()

      {:ok, [_, updated_order_2]} =
        Tai.Trading.OrderStore.find_by_and_update(
          [client_id: order_2.client_id],
          status: Tai.Trading.OrderStatus.error()
        )

      {:ok, [_, updated_order_3]} =
        Tai.Trading.OrderStore.find_by_and_update(
          [client_id: order_3.client_id],
          status: Tai.Trading.OrderStatus.error()
        )

      error_orders =
        [
          client_id: [updated_order_2.client_id, updated_order_3.client_id],
          status: Tai.Trading.OrderStatus.error()
        ]
        |> Tai.Trading.OrderStore.where()
        |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

      assert error_orders == [updated_order_2, updated_order_3]
    end
  end
end
