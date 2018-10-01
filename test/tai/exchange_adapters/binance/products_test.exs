defmodule Tai.ExchangeAdapters.Binance.ProductsTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    on_exit(fn ->
      Tai.Exchanges.ProductStore.clear()
    end)

    HTTPoison.start()
    Process.register(self(), :test)
    :ok
  end

  test "retrieves the trade rules for each product" do
    config = %Tai.Exchanges.Config{
      id: :binance,
      supervisor: Tai.ExchangeAdapters.Binance.Supervisor,
      accounts: %{}
    }

    exchange_id = config.id
    symbol = :ltc_btc
    key = {config.id, symbol}
    Tai.Boot.subscribe_products(config.id)

    use_cassette "exchange_adapters/shared/products/#{exchange_id}/init_success" do
      start_supervised!({config.supervisor, config})

      assert_receive {:fetched_products, :ok, ^exchange_id}, 1_000
    end

    assert {:ok, %Tai.Exchanges.Product{} = product} = Tai.Exchanges.ProductStore.find(key)
    assert Decimal.cmp(product.min_notional, Decimal.new(0.001)) == :eq
    assert Decimal.cmp(product.min_price, Decimal.new(0.000001)) == :eq
    assert Decimal.cmp(product.min_size, Decimal.new(0.01)) == :eq
    assert Decimal.cmp(product.price_increment, Decimal.new(0.000001)) == :eq
    assert Decimal.cmp(product.max_price, Decimal.new(100_000.0)) == :eq
    assert Decimal.cmp(product.max_size, Decimal.new(100_000.0)) == :eq
    assert Decimal.cmp(product.size_increment, Decimal.new(0.01)) == :eq

    Tai.Boot.unsubscribe_products(exchange_id)
  end
end
