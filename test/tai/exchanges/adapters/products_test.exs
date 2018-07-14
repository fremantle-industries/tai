defmodule Tai.Exchanges.Adapters.ProductsTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @adapters [
    %Tai.Exchanges.Config{
      id: :binance,
      supervisor: Tai.ExchangeAdapters.Binance.Supervisor
    }
  ]

  setup_all do
    HTTPoison.start()
    Process.register(self(), :test)
    :ok
  end

  @adapters
  |> Enum.map(fn config ->
    @config config

    test "#{config.id} retrieves the product information for the exchange" do
      exchange_id = @config.id
      Tai.Boot.subscribe_products(@config.id)
      key = {@config.id, :btc_usdt}

      assert {:error, :not_found} = Tai.Exchanges.Products.find(key)

      use_cassette "exchange_adapters/shared/products/#{exchange_id}/init_success" do
        start_supervised!({@config.supervisor, @config})

        assert_receive {:fetched_products, :ok, ^exchange_id}, 1000
      end

      assert Tai.Exchanges.Products.find(key) == {
               :ok,
               %Tai.Exchanges.Product{
                 exchange_id: :binance,
                 symbol: :btc_usdt,
                 exchange_symbol: "BTCUSDT",
                 status: :trading,
                 min_price: Decimal.new("0.01000000"),
                 max_price: Decimal.new("10000000.00000000"),
                 tick_size: Decimal.new("0.01000000"),
                 min_size: Decimal.new("0.00000100"),
                 max_size: Decimal.new("10000000.00000000"),
                 step_size: Decimal.new("0.00000100")
               }
             }

      Tai.Boot.unsubscribe_products(exchange_id)
    end
  end)
end
