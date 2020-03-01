defmodule Tai.Venues.Adapters.ProductsTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    on_exit(fn ->
      :ok = Application.stop(:tai_events)
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    start_supervised!(Tai.TestSupport.Mocks.Server)
    HTTPoison.start()
  end

  @test_venues Tai.TestSupport.Helpers.test_venue_adapters_products()

  @test_venues
  |> Enum.map(fn {_, venue} ->
    @venue venue

    test "#{venue.id} retrieves the product information for the exchange" do
      setup_adapter(@venue.id)

      use_cassette "venue_adapters/shared/products/#{@venue.id}/success" do
        assert {:ok, products} = Tai.Venues.Client.products(@venue)
        assert Enum.count(products) > 0
        assert [%Tai.Venues.Product{} = product | _] = products
        assert product.venue_id == @venue.id
        assert product.symbol != nil
        assert product.status != nil
        assert %Decimal{} = product.min_size
        assert %Decimal{} = product.size_increment
      end
    end
  end)

  def setup_adapter(:mock) do
    Tai.TestSupport.Mocks.Responses.Products.for_venue(
      :mock,
      [
        %{
          symbol: :btc_usd,
          status: Tai.Venues.ProductStatus.trading(),
          min_notional: Decimal.new("0.0001"),
          min_size: Decimal.new("0.0001"),
          min_price: Decimal.new("0.01"),
          size_increment: Decimal.new("0.001")
        },
        %{
          symbol: :ltc_usd,
          status: Tai.Venues.ProductStatus.trading(),
          min_notional: Decimal.new("0.0001"),
          min_size: Decimal.new("0.0001"),
          min_price: Decimal.new("0.01"),
          size_increment: Decimal.new("0.001")
        }
      ]
    )
  end

  def setup_adapter(_), do: nil
end
