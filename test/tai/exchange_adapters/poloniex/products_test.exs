defmodule Tai.ExchangeAdapters.Poloniex.ProductsTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    on_exit(fn ->
      Tai.Exchanges.Products.clear()
    end)

    HTTPoison.start()
    Process.register(self(), :test)
    :ok
  end

  test "retrieves the trade rules for each product" do
    config = %Tai.Exchanges.Config{
      id: :poloniex,
      supervisor: Tai.ExchangeAdapters.Poloniex.Supervisor
    }

    exchange_id = config.id
    symbol = :ltc_btc
    key = {config.id, symbol}
    Tai.Boot.subscribe_products(config.id)

    use_cassette "exchange_adapters/shared/products/#{exchange_id}/init_success" do
      start_supervised!({config.supervisor, config})

      assert_receive {:fetched_products, :ok, ^exchange_id}, 1_000
    end

    assert {:ok, %Tai.Exchanges.Product{} = product} = Tai.Exchanges.Products.find(key)
    assert Decimal.cmp(product.min_notional, Decimal.new(0.0001)) == :eq
    assert product.min_price == nil
    assert product.min_size == nil
    assert product.price_increment == nil
    assert product.max_price == nil
    assert product.max_size == nil
    assert product.size_increment == nil

    Tai.Boot.unsubscribe_products(exchange_id)
  end

  test "halts products that are frozen" do
    config = %Tai.Exchanges.Config{
      id: :poloniex,
      supervisor: Tai.ExchangeAdapters.Poloniex.Supervisor
    }

    exchange_id = config.id
    symbol = :gas_eth
    key = {config.id, symbol}
    Tai.Boot.subscribe_products(config.id)

    use_cassette "exchange_adapters/shared/products/#{exchange_id}/init_with_frozen" do
      start_supervised!({config.supervisor, config})

      assert_receive {:fetched_products, :ok, ^exchange_id}, 1_000
    end

    assert {:ok, %Tai.Exchanges.Product{} = product} = Tai.Exchanges.Products.find(key)
    assert product.status == :halt

    Tai.Boot.unsubscribe_products(exchange_id)
  end
end
