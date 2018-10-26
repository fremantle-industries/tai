defmodule Tai.VenueAdapters.Binance.ProductsTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @test_adapters Tai.TestSupport.Helpers.test_exchange_adapters()

  setup_all do
    HTTPoison.start()
    adapter = find_adapter(@test_adapters, :binance)
    {:ok, %{adapter: adapter}}
  end

  test "retrieves the trade rules for each product", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/products/binance/success" do
      assert {:ok, products} = Tai.Exchanges.Exchange.products(adapter)
      assert %Tai.Exchanges.Product{} = product = find_product_by_symbol(products, :ltc_btc)
      assert Decimal.cmp(product.min_notional, Decimal.new(0.001)) == :eq
      assert Decimal.cmp(product.min_price, Decimal.new(0.000001)) == :eq
      assert Decimal.cmp(product.min_size, Decimal.new(0.01)) == :eq
      assert Decimal.cmp(product.price_increment, Decimal.new(0.000001)) == :eq
      assert Decimal.cmp(product.max_price, Decimal.new(100_000.0)) == :eq
      assert Decimal.cmp(product.max_size, Decimal.new(100_000.0)) == :eq
      assert Decimal.cmp(product.size_increment, Decimal.new(0.01)) == :eq
    end
  end

  test "returns an error tuple when the secret is invalid", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/products/binance/error_invalid_secret" do
      assert Tai.Exchanges.Exchange.products(adapter) == {
               :error,
               %Tai.CredentialError{reason: "API-key format invalid."}
             }
    end
  end

  test "returns an error tuple when the api key is invalid", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/products/binance/error_invalid_api_key" do
      assert Tai.Exchanges.Exchange.products(adapter) == {
               :error,
               %Tai.CredentialError{reason: "API-key format invalid."}
             }
    end
  end

  test "returns an error tuple when the request times out", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/products/binance/error_timeout" do
      assert Tai.Exchanges.Exchange.products(adapter) == {
               :error,
               %Tai.TimeoutError{reason: "network request timed out"}
             }
    end
  end

  def find_adapter(adapters, exchange_id) do
    Enum.find(adapters, &(&1.id == exchange_id))
  end

  def find_product_by_symbol(products, symbol) do
    Enum.find(products, &(&1.symbol == symbol))
  end
end
