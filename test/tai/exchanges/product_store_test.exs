defmodule Tai.Exchanges.ProductStoreTest do
  use ExUnit.Case, async: false
  doctest Tai.Exchanges.ProductStore

  setup do
    on_exit(fn ->
      Tai.Exchanges.ProductStore.clear()
    end)

    product = %Tai.Exchanges.Product{
      exchange_id: :my_exchange,
      symbol: :btc_usdt,
      exchange_symbol: "BTC_USDT",
      status: :trading,
      min_price: Decimal.new("0.00100000"),
      max_price: Decimal.new("100000.00000000"),
      price_increment: Decimal.new("0.00100000"),
      min_size: Decimal.new("0.00100000"),
      max_size: Decimal.new("10000.00000000"),
      size_increment: Decimal.new("0.00100000"),
      min_notional: Decimal.new("0.01000000")
    }

    {:ok, %{product: product}}
  end

  describe "#upsert" do
    test "inserts the product into the 'products' ETS table", %{product: product} do
      assert Tai.Exchanges.ProductStore.upsert(product) == :ok

      assert [{{:my_exchange, :btc_usdt}, ^product}] =
               :ets.lookup(Tai.Exchanges.ProductStore, {:my_exchange, :btc_usdt})
    end
  end

  describe "#count" do
    test "returns the number of products in the ETS table", %{product: product} do
      assert Tai.Exchanges.ProductStore.count() == 0

      assert Tai.Exchanges.ProductStore.upsert(product) == :ok

      assert Tai.Exchanges.ProductStore.count() == 1
    end
  end

  describe "#find" do
    test "returns the product in an ok tuple", %{product: product} do
      assert Tai.Exchanges.ProductStore.upsert(product) == :ok

      assert {:ok, ^product} = Tai.Exchanges.ProductStore.find({:my_exchange, :btc_usdt})
    end

    test "returns an error tuple when the key is not found" do
      assert Tai.Exchanges.ProductStore.find({:my_exchange_does_not_exist, :btc_usdt}) ==
               {:error, :not_found}
    end
  end

  describe "#where" do
    test "returns a list of products that matche all attributes", %{product: product} do
      assert Tai.Exchanges.ProductStore.upsert(product) == :ok

      assert Tai.Exchanges.ProductStore.where(exchange_id: :other_exchange, symbol: :btc_usdt) ==
               []

      assert [matched_product] =
               Tai.Exchanges.ProductStore.where(
                 exchange_id: product.exchange_id,
                 symbol: product.symbol
               )

      assert matched_product == product
    end
  end

  describe "#clear" do
    test "removes the existing items in the 'products' ETS table", %{product: product} do
      assert Tai.Exchanges.ProductStore.upsert(product) == :ok
      assert Tai.Exchanges.ProductStore.count() == 1

      assert Tai.Exchanges.ProductStore.clear() == :ok
      assert Tai.Exchanges.ProductStore.count() == 0
    end
  end

  describe "#all" do
    test "returns a list of all the products", %{product: product} do
      assert Tai.Exchanges.ProductStore.all() == []

      assert Tai.Exchanges.ProductStore.upsert(product) == :ok

      assert [^product] = Tai.Exchanges.ProductStore.all()
    end
  end
end
