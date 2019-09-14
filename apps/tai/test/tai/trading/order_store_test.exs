defmodule Tai.Trading.OrderStoreTest do
  use ExUnit.Case, async: true
  doctest Tai.Trading.OrderStore
  alias Tai.Trading.OrderStore

  @store_id __MODULE__

  setup do
    {:ok, _} = start_supervised({OrderStore, [id: @store_id]})
    :ok
  end

  test ".enqueue creates an order from the submission" do
    submission = build_submission()

    assert {:ok, order} = OrderStore.enqueue(submission, @store_id)
    assert order.status == :enqueued
  end

  describe ".update" do
    test "updates the actions attributes and timestamps the update" do
      assert {:ok, order} = enqueue()

      action = struct!(Tai.Trading.OrderStore.Actions.Skip, client_id: order.client_id)
      assert {:ok, {old, updated}} = OrderStore.update(action, @store_id)

      assert old.status == :enqueued
      assert updated.status == :skip
      assert updated.leaves_qty == Decimal.new(0)
      assert updated.updated_at != nil
    end

    test "returns an error when the order can't be found" do
      action = struct(Tai.Trading.OrderStore.Actions.Skip, client_id: "not_found")
      assert {:error, {:not_found, not_found_action}} = OrderStore.update(action, @store_id)
      assert not_found_action == action
    end

    test "returns an error when the current status is invalid" do
      assert {:ok, order} = enqueue()

      action = struct!(Tai.Trading.OrderStore.Actions.Skip, client_id: order.client_id)
      assert {:ok, _} = OrderStore.update(action, @store_id)

      assert {:error, reason} = OrderStore.update(action, @store_id)
      assert {:invalid_status, :skip, :enqueued, invalid_action} = reason
      assert invalid_action == action
    end
  end

  describe ".find_by_client_id" do
    test "returns the order " do
      {:ok, order} = enqueue()
      assert {:ok, ^order} = OrderStore.find_by_client_id(order.client_id, @store_id)
    end

    test "returns an error when no match was found" do
      assert OrderStore.find_by_client_id("not found", @store_id) == {:error, :not_found}
    end
  end

  test ".all returns a list of current orders" do
    assert OrderStore.all(@store_id) == []
    {:ok, order} = enqueue()
    assert OrderStore.all(@store_id) == [order]
  end

  test ".count returns the total number of orders" do
    assert OrderStore.count(@store_id) == 0
    {:ok, _} = enqueue()
    assert OrderStore.count(@store_id) == 1
  end

  defp enqueue(store_id \\ @store_id), do: build_submission() |> OrderStore.enqueue(store_id)

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
