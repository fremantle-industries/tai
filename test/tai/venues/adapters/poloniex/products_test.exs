defmodule Tai.Venues.Adapters.Poloniex.ProductsTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters()

  setup_all do
    HTTPoison.start()
    adapter = @test_adapters |> Map.fetch!(:poloniex)
    {:ok, %{adapter: adapter}}
  end

  test "retrieves the trade rules for each product", %{adapter: adapter} do
    use_cassette "venue_adapters/shared/products/poloniex/success" do
      assert {:ok, products} = Tai.Venue.products(adapter)
      assert %Tai.Venues.Product{} = product = find_product_by_symbol(products, :ltc_btc)
      assert product.price_increment == Decimal.new("0.00000001")
      assert product.size_increment == Decimal.new("0.000001")
      assert product.min_price == Decimal.new("0.00000001")
      assert product.min_size == Decimal.new("0.000001")
      assert product.min_notional == Decimal.new("0.0001")
      assert product.max_price == Decimal.new("100000.0")
      assert product.max_size == nil
    end
  end

  test "returns an error tuple when the request times out", %{adapter: adapter} do
    use_cassette "venue_adapters/shared/products/poloniex/error_timeout" do
      assert Tai.Venue.products(adapter) == {:error, :timeout}
    end
  end

  def find_product_by_symbol(products, symbol) do
    Enum.find(products, &(&1.symbol == symbol))
  end
end
