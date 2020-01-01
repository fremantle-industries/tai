defmodule Tai.Venues.Adapters.Bitmex.ProductsTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import Mock

  @test_venues Tai.TestSupport.Helpers.test_venue_adapters()

  setup_all do
    HTTPoison.start()
    venue = @test_venues |> Map.fetch!(:bitmex)
    {:ok, %{venue: venue}}
  end

  test "retrieves the trade rules for each product", %{venue: venue} do
    use_cassette "venue_adapters/shared/products/bitmex/success" do
      assert {:ok, products} = Tai.Venues.Client.products(venue)
      assert %Tai.Venues.Product{} = product = find_product_by_symbol(products, :xbtusd)
      assert product.venue_id == :bitmex
      assert product.venue_symbol == "XBTUSD"
      assert product.status == :trading
      assert %Decimal{} = product.price_increment
      assert %Decimal{} = product.size_increment
      assert %Decimal{} = product.maker_fee
      assert %Decimal{} = product.taker_fee
    end
  end

  test "bubbles errors without the rate limit", %{venue: venue} do
    with_mock HTTPoison, request: fn _url -> {:error, %HTTPoison.Error{reason: :timeout}} end do
      assert Tai.Venues.Client.products(venue) == {:error, :timeout}
    end
  end

  def find_product_by_symbol(products, symbol) do
    Enum.find(products, &(&1.symbol == symbol))
  end
end
