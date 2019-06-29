defmodule Tai.Trading.OrderStoreTest do
  use ExUnit.Case
  doctest Tai.Trading.OrderStore
  alias Tai.Trading.OrderStore

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test ".enqueue creates an order from the submission" do
    submission = build_submission()

    assert {:ok, order} = OrderStore.enqueue(submission)
    assert order.status == :enqueued
  end

  describe ".update" do
    test "updates the actions attributes" do
      assert {:ok, order} = enqueue()

      action = struct!(Tai.Trading.OrderStore.Actions.Skip, client_id: order.client_id)
      assert {:ok, {old, updated}} = OrderStore.update(action)

      assert old.status == :enqueued
      assert updated.status == :skip
      assert updated.leaves_qty == Decimal.new(0)
    end

    test "returns an error when the order can't be found" do
      action = struct(Tai.Trading.OrderStore.Actions.Skip, client_id: "not_found")
      assert OrderStore.update(action) == {:error, :not_found}
    end

    test "returns an error when the current status is invalid" do
      assert {:ok, order} = enqueue()

      action = struct!(Tai.Trading.OrderStore.Actions.Skip, client_id: order.client_id)
      assert {:ok, _} = OrderStore.update(action)

      assert {:error, reason} = OrderStore.update(action)
      assert reason == {:invalid_status, :skip, :enqueued}
    end
  end

  describe ".find_by_client_id" do
    test "returns the order " do
      {:ok, order} = enqueue()
      assert {:ok, ^order} = OrderStore.find_by_client_id(order.client_id)
    end

    test "returns an error when no match was found" do
      assert OrderStore.find_by_client_id("not found") == {:error, :not_found}
    end
  end

  test ".all returns a list of current orders" do
    assert OrderStore.all() == []
    {:ok, order} = enqueue()
    assert OrderStore.all() == [order]
  end

  test ".count returns the total number of orders" do
    assert OrderStore.count() == 0
    {:ok, _} = enqueue()
    assert OrderStore.count() == 1
  end

  defp enqueue, do: build_submission() |> OrderStore.enqueue()

  defp build_submission do
    struct(Tai.Trading.OrderSubmissions.BuyLimitGtc,
      venue_id: :test_exchange_a,
      account_id: :main,
      product_symbol: :btc_usd,
      price: Decimal.new("100.1"),
      qty: Decimal.new("1.1")
    )
  end
end
