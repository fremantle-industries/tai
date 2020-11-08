defmodule Tai.Venues.Adapters.Gdax.ProductsTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @venue Tai.TestSupport.Helpers.test_venue_adapter(:gdax)

  setup_all do
    HTTPoison.start()
    :ok
  end

  test "retrieves the trade rules for each product" do
    use_cassette "venue_adapters/shared/products/gdax/success" do
      assert {:ok, products} = Tai.Venues.Client.products(@venue)
      assert %Tai.Venues.Product{} = product = find_product_by_symbol(products, :ltc_btc)
      assert Decimal.compare(product.min_notional, Decimal.new("0.000001")) == :eq
      assert Decimal.compare(product.min_price, Decimal.new("0.00001")) == :eq
      assert Decimal.compare(product.min_size, Decimal.new("0.1")) == :eq
      assert Decimal.compare(product.max_size, Decimal.new(2000)) == :eq
      assert Decimal.compare(product.price_increment, Decimal.new("0.00001")) == :eq
      assert Decimal.compare(product.size_increment, Decimal.new("0.1")) == :eq
    end
  end

  test "returns an error tuple when the passphrase is invalid" do
    use_cassette "venue_adapters/shared/products/gdax/error_invalid_passphrase" do
      assert {:error, {:credentials, reason}} = Tai.Venues.Client.products(@venue)
      assert reason == "Invalid Passphrase"
    end
  end

  test "returns an error tuple when the api key is invalid" do
    use_cassette "venue_adapters/shared/products/gdax/error_invalid_api_key" do
      assert {:error, {:credentials, reason}} = Tai.Venues.Client.products(@venue)
      assert reason == "Invalid API Key"
    end
  end

  test "returns an error tuple when the request times out" do
    use_cassette "venue_adapters/shared/products/gdax/error_timeout" do
      assert Tai.Venues.Client.products(@venue) == {:error, :timeout}
    end
  end

  test "returns an error tuple when down for maintenance" do
    use_cassette "venue_adapters/shared/products/gdax/error_maintenance" do
      assert {:error, reason} = Tai.Venues.Client.products(@venue)

      assert {:service_unavailable, msg} = reason

      assert msg ==
               "GDAX is currently under maintenance. For updates please see https://status.gdax.com/"
    end
  end

  def find_product_by_symbol(products, symbol) do
    Enum.find(products, &(&1.symbol == symbol))
  end
end
