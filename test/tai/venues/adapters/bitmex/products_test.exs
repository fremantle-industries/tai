defmodule Tai.VenueAdapters.Bitmex.ProductsTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters()

  setup_all do
    HTTPoison.start()
    adapter = find_adapter(@test_adapters, :bitmex)
    {:ok, %{adapter: adapter}}
  end

  test "retrieves the trade rules for each product", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/products/bitmex/success" do
      assert {:ok, products} = Tai.Venue.products(adapter)
      assert %Tai.Venues.Product{} = product = find_product_by_symbol(products, :xbtusd)
      assert product.exchange_id == :bitmex
      assert product.exchange_symbol == "XBTUSD"
      assert product.status == :trading
      assert %Decimal{} = product.price_increment
      assert %Decimal{} = product.size_increment
      assert %Decimal{} = product.maker_fee
      assert %Decimal{} = product.taker_fee
    end
  end

  test "returns an error tuple on timeout", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/products/bitmex/error_timeout" do
      assert Tai.Venue.products(adapter) ==
               {:error, %Tai.TimeoutError{reason: "network request timed out"}}
    end
  end

  def find_adapter(adapters, exchange_id) do
    Enum.find(adapters, &(&1.id == exchange_id))
  end

  def find_product_by_symbol(products, symbol) do
    Enum.find(products, &(&1.symbol == symbol))
  end
end
