defmodule Tai.Trading.OrderStoreTest do
  use ExUnit.Case
  doctest Tai.Trading.OrderStore

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  describe ".add" do
    @sides [:buy, :sell]

    @sides
    |> Enum.each(fn side ->
      @side side

      test "enqueues #{side} gtc orders" do
        submission = build_submission(@side, :gtc, post_only: true)

        assert {:ok, %Tai.Trading.Order{} = order} = Tai.Trading.OrderStore.add(submission)

        assert order.client_id != nil
        assert order.side == @side
        assert order.post_only == true
        assert order.time_in_force == :gtc
        assert order.exchange_id == :test_exchange_a
        assert order.account_id == :main
        assert order.symbol == :btc_usd
        assert %Decimal{} = order.price
        assert %Decimal{} = order.size
        assert order.status == :enqueued
        assert %DateTime{} = order.enqueued_at
      end

      test "enqueues #{side} fok orders" do
        submission = build_submission(@side, :fok)

        assert {:ok, %Tai.Trading.Order{} = order} = Tai.Trading.OrderStore.add(submission)

        assert order.client_id != nil
        assert order.side == @side
        assert order.post_only == false
        assert order.time_in_force == :fok
        assert order.exchange_id == :test_exchange_a
        assert order.account_id == :main
        assert order.symbol == :btc_usd
        assert %Decimal{} = order.price
        assert %Decimal{} = order.size
        assert order.status == :enqueued
        assert %DateTime{} = order.enqueued_at
      end

      test "enqueues #{side} ioc orders" do
        submission = build_submission(@side, :ioc)

        assert {:ok, %Tai.Trading.Order{} = order} = Tai.Trading.OrderStore.add(submission)

        assert order.client_id != nil
        assert order.side == @side
        assert order.time_in_force == :ioc
        assert order.post_only == false
        assert order.exchange_id == :test_exchange_a
        assert order.account_id == :main
        assert order.symbol == :btc_usd
        assert %Decimal{} = order.price
        assert %Decimal{} = order.size
        assert order.status == :enqueued
        assert %DateTime{} = order.enqueued_at
      end
    end)
  end

  describe ".find" do
    test "returns an ok tuple with the order " do
      {:ok, order} = submit_order()

      assert {:ok, ^order} = Tai.Trading.OrderStore.find(order.client_id)
    end

    test "returns an error tuple when no match was found" do
      assert Tai.Trading.OrderStore.find("client_id_doesnt_exist") == {:error, :not_found}
    end
  end

  describe ".find_by_and_update" do
    test "can change the whitelist of attributes" do
      {:ok, order} = submit_order()

      assert {:ok, {old_order, updated_order}} =
               Tai.Trading.OrderStore.find_by_and_update(
                 [client_id: order.client_id],
                 client_id: "changed_client_id",
                 status: :error
               )

      assert old_order == order
      assert updated_order.status == :error
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
      {:ok, _} = submit_order()
      {:ok, _} = submit_order()

      assert {:error, :multiple_orders_found} =
               Tai.Trading.OrderStore.find_by_and_update(
                 [status: :enqueued],
                 []
               )
    end
  end

  test ".all returns a list of current orders" do
    assert Tai.Trading.OrderStore.all() == []

    {:ok, order} = submit_order()

    assert Tai.Trading.OrderStore.all() == [order]
  end

  describe ".count" do
    test "count returns the total number of orders" do
      assert Tai.Trading.OrderStore.count() == 0

      {:ok, _} = submit_order()

      assert Tai.Trading.OrderStore.count() == 1
    end

    test "count can filter by status" do
      assert Tai.Trading.OrderStore.count(status: :enqueued) == 0
      assert Tai.Trading.OrderStore.count(status: :pending) == 0

      {:ok, _} = submit_order()

      assert Tai.Trading.OrderStore.count(status: :enqueued) == 1
      assert Tai.Trading.OrderStore.count(status: :pending) == 0
    end
  end

  describe ".where" do
    test "can filter by a singular client_id" do
      {:ok, _} = submit_order()
      {:ok, order_2} = submit_order()
      {:ok, _} = submit_order()

      assert Tai.Trading.OrderStore.where(client_id: order_2.client_id) == [order_2]
      assert Tai.Trading.OrderStore.where(client_id: "client_id_does_not_exist") == []
    end

    test "can filter by multiple client_ids" do
      {:ok, _} = submit_order()
      {:ok, order_2} = submit_order()
      {:ok, order_3} = submit_order()

      found_orders =
        [client_id: [order_2.client_id, order_3.client_id]]
        |> Tai.Trading.OrderStore.where()
        |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

      assert found_orders == [order_2, order_3]
      assert Tai.Trading.OrderStore.where(client_id: []) == []
      assert Tai.Trading.OrderStore.where(client_id: ["client_id_does_not_exist"]) == []
    end

    test "can filter by a single status" do
      {:ok, order_1} = submit_order()
      {:ok, order_2} = submit_order()

      found_orders =
        [status: :enqueued]
        |> Tai.Trading.OrderStore.where()
        |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

      assert found_orders == [order_1, order_2]
      assert Tai.Trading.OrderStore.where(status: :pending) == []
      assert Tai.Trading.OrderStore.where(status: :status_does_not_exist) == []
    end

    test "can filter by multiple status'" do
      {:ok, order_1} = submit_order()
      {:ok, order_2} = submit_order()
      {:ok, order_3} = submit_order()

      {:ok, {_, updated_order_2}} =
        Tai.Trading.OrderStore.find_by_and_update(
          [client_id: order_2.client_id],
          status: :pending
        )

      Tai.Trading.OrderStore.find_by_and_update(
        [client_id: order_3.client_id],
        status: :error
      )

      found_orders =
        [status: [:enqueued, :pending]]
        |> Tai.Trading.OrderStore.where()
        |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

      assert found_orders == [order_1, updated_order_2]
      assert Tai.Trading.OrderStore.where(status: []) == []
      assert Tai.Trading.OrderStore.where(status: [:status_does_not_exist]) == []
    end

    test "can filter by client_ids and status" do
      submit_order()
      {:ok, order_2} = submit_order()
      {:ok, order_3} = submit_order()

      {:ok, {_, updated_order_2}} =
        Tai.Trading.OrderStore.find_by_and_update(
          [client_id: order_2.client_id],
          status: :error
        )

      {:ok, {_, updated_order_3}} =
        Tai.Trading.OrderStore.find_by_and_update(
          [client_id: order_3.client_id],
          status: :error
        )

      error_orders =
        [
          client_id: [updated_order_2.client_id, updated_order_3.client_id],
          status: :error
        ]
        |> Tai.Trading.OrderStore.where()
        |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))

      assert error_orders == [updated_order_2, updated_order_3]
    end
  end

  defp submit_order do
    :buy
    |> build_submission(:fok)
    |> Tai.Trading.OrderStore.add()
  end

  def build_submission(:buy, :gtc, post_only: post_only) do
    %Tai.Trading.OrderSubmissions.BuyLimitGtc{
      venue_id: :test_exchange_a,
      account_id: :main,
      product_symbol: :btc_usd,
      price: Decimal.new("100.1"),
      qty: Decimal.new("1.1"),
      post_only: post_only
    }
  end

  def build_submission(:sell, :gtc, post_only: post_only) do
    %Tai.Trading.OrderSubmissions.SellLimitGtc{
      venue_id: :test_exchange_a,
      account_id: :main,
      product_symbol: :btc_usd,
      price: Decimal.new("50000.5"),
      qty: Decimal.new("0.1"),
      post_only: post_only
    }
  end

  def build_submission(:buy, :fok) do
    %Tai.Trading.OrderSubmissions.BuyLimitFok{
      venue_id: :test_exchange_a,
      account_id: :main,
      product_symbol: :btc_usd,
      price: Decimal.new("100.1"),
      qty: Decimal.new("1.1")
    }
  end

  def build_submission(:sell, :fok) do
    %Tai.Trading.OrderSubmissions.SellLimitFok{
      venue_id: :test_exchange_a,
      account_id: :main,
      product_symbol: :btc_usd,
      price: Decimal.new("50000.5"),
      qty: Decimal.new("0.1")
    }
  end

  def build_submission(:buy, :ioc) do
    %Tai.Trading.OrderSubmissions.BuyLimitIoc{
      venue_id: :test_exchange_a,
      account_id: :main,
      product_symbol: :btc_usd,
      price: Decimal.new("100.1"),
      qty: Decimal.new("1.1")
    }
  end

  def build_submission(:sell, :ioc) do
    %Tai.Trading.OrderSubmissions.SellLimitIoc{
      venue_id: :test_exchange_a,
      account_id: :main,
      product_symbol: :btc_usd,
      price: Decimal.new("50000.5"),
      qty: Decimal.new("0.1")
    }
  end
end
