defmodule Tai.VenueAdapters.Gdax.ProductsTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters()

  setup_all do
    HTTPoison.start()
    adapter = find_adapter(@test_adapters, :gdax)
    {:ok, %{adapter: adapter}}
  end

  test "retrieves the trade rules for each product", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/products/gdax/success" do
      assert {:ok, products} = Tai.Exchanges.Exchange.products(adapter)
      assert %Tai.Exchanges.Product{} = product = find_product_by_symbol(products, :ltc_btc)
      assert Decimal.cmp(product.min_notional, Decimal.new(0.000001)) == :eq
      assert Decimal.cmp(product.min_price, Decimal.new(0.00001)) == :eq
      assert Decimal.cmp(product.min_size, Decimal.new(0.1)) == :eq
      assert Decimal.cmp(product.max_size, Decimal.new(2000)) == :eq
      assert Decimal.cmp(product.price_increment, Decimal.new(0.00001)) == :eq
      assert Decimal.cmp(product.size_increment, Decimal.new(0.1)) == :eq
    end
  end

  test "returns an error tuple when the passphrase is invalid", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/products/gdax/error_invalid_passphrase" do
      assert Tai.Exchanges.Exchange.products(adapter) == {
               :error,
               %Tai.CredentialError{reason: "Invalid Passphrase"}
             }
    end
  end

  test "returns an error tuple when the api key is invalid", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/products/gdax/error_invalid_api_key" do
      assert Tai.Exchanges.Exchange.products(adapter) == {
               :error,
               %Tai.CredentialError{reason: "Invalid API Key"}
             }
    end
  end

  test "returns an error tuple when the request times out", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/products/gdax/error_timeout" do
      assert Tai.Exchanges.Exchange.products(adapter) == {
               :error,
               %Tai.TimeoutError{reason: "network request timed out"}
             }
    end
  end

  test "returns an error tuple when down for maintenance", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/products/gdax/error_maintenance" do
      assert Tai.Exchanges.Exchange.products(adapter) == {
               :error,
               %Tai.ServiceUnavailableError{
                 reason:
                   "GDAX is currently under maintenance. For updates please see https://status.gdax.com/"
               }
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
