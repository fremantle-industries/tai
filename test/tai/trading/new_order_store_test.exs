defmodule Tai.Trading.NewOrderStoreTest do
  use ExUnit.Case
  doctest Tai.Trading.NewOrderStore

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  describe ".add" do
    test "enqueues order submissions" do
      submission =
        struct(Tai.Trading.OrderSubmissions.BuyLimitGtc, %{
          price: Decimal.new(1000),
          qty: Decimal.new(1)
        })

      assert {:ok, %Tai.Trading.Order{} = order} = Tai.Trading.NewOrderStore.add(submission)
      assert order.status == :enqueued
    end
  end

  describe ".find_by_client_id" do
    test "returns an ok tuple with the order " do
      {:ok, order} = submit_order()

      assert {:ok, ^order} = Tai.Trading.NewOrderStore.find_by_client_id(order.client_id)
    end

    test "returns an error tuple when no match was found" do
      assert Tai.Trading.NewOrderStore.find_by_client_id("client_id_doesnt_exist") ==
               {:error, :not_found}
    end
  end

  test ".all returns a list of current orders" do
    assert Tai.Trading.NewOrderStore.all() == []

    {:ok, order} = submit_order()

    assert Tai.Trading.NewOrderStore.all() == [order]
  end

  test ".count returns the total number of orders" do
    assert Tai.Trading.NewOrderStore.count() == 0

    {:ok, _} = submit_order()

    assert Tai.Trading.NewOrderStore.count() == 1
  end

  defp submit_order do
    %Tai.Trading.OrderSubmissions.BuyLimitFok{
      venue_id: :test_exchange_a,
      account_id: :main,
      product_symbol: :btc_usd,
      price: Decimal.new("100.1"),
      qty: Decimal.new("1.1")
    }
    |> Tai.Trading.NewOrderStore.add()
  end
end
