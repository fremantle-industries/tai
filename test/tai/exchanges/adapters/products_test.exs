defmodule Tai.Exchanges.Adapters.ProductsTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @adapters [
    %Tai.Exchanges.Config{
      id: :binance,
      supervisor: Tai.ExchangeAdapters.Binance.Supervisor,
      products: "*"
    },
    %Tai.Exchanges.Config{
      id: :poloniex,
      supervisor: Tai.ExchangeAdapters.Poloniex.Supervisor,
      products: "*"
    },
    %Tai.Exchanges.Config{
      id: :gdax,
      supervisor: Tai.ExchangeAdapters.Gdax.Supervisor,
      products: "*"
    }
  ]

  setup_all do
    on_exit(fn ->
      Tai.Exchanges.Products.clear()
    end)

    HTTPoison.start()
    Process.register(self(), :test)
    :ok
  end

  @adapters
  |> Enum.map(fn config ->
    @config config

    test "#{config.id} retrieves the product information for the exchange" do
      exchange_id = @config.id
      symbol = :ltc_btc
      Tai.Boot.subscribe_products(@config.id)
      key = {@config.id, symbol}

      assert {:error, :not_found} = Tai.Exchanges.Products.find(key)

      use_cassette "exchange_adapters/shared/products/#{exchange_id}/init_success" do
        start_supervised!({@config.supervisor, @config})

        assert_receive {:fetched_products, :ok, ^exchange_id}, 1_000
      end

      assert {:ok, %Tai.Exchanges.Product{} = product} = Tai.Exchanges.Products.find(key)
      assert ^exchange_id = product.exchange_id
      assert ^symbol = product.symbol
      assert product.exchange_symbol =~ "LTC"
      assert product.exchange_symbol =~ "BTC"
      assert Decimal.cmp(product.min_notional, Decimal.new(0)) == :gt
      assert product.status == :trading

      Tai.Boot.unsubscribe_products(exchange_id)
    end
  end)
end
