defmodule Tai.VenueAdapters.Poloniex.ProductsTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters()

  setup_all do
    HTTPoison.start()
    adapter = find_adapter(@test_adapters, :poloniex)
    {:ok, %{adapter: adapter}}
  end

  test "retrieves the trade rules for each product", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/products/poloniex/success" do
      assert {:ok, products} = Tai.Venue.products(adapter)
      assert %Tai.Venues.Product{} = product = find_product_by_symbol(products, :ltc_btc)
      assert product.min_notional == Decimal.new("0.0001")
      assert product.min_price == Decimal.new("0.00000001")
      assert product.min_size == Decimal.new("0.000001")
      assert product.max_price == Decimal.new("100000.0")
      assert product.max_size == nil
      assert product.price_increment == nil
      assert product.size_increment == Decimal.new("0.000001")
    end
  end

  test "returns an error tuple when the request times out", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/products/poloniex/error_timeout" do
      assert Tai.Venue.products(adapter) == {
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
