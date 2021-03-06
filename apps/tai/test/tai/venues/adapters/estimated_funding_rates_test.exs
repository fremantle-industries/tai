defmodule Tai.Venues.Adapters.EstimatedFundingRatesTest do
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

  @test_venues Tai.TestSupport.Helpers.test_venue_adapters_funding_rates()

  @test_venues
  |> Enum.map(fn venue ->
    @venue venue

    test "#{venue.id} retrieves the product information for the exchange" do
      setup_adapter(@venue.id)

      use_cassette "venue_adapters/shared/estimated_funding_rates/#{@venue.id}/success" do
        assert {:ok, estimated_funding_rates} = Tai.Venues.Client.estimated_funding_rates(@venue)
        assert Enum.count(estimated_funding_rates) > 0
        assert [%Tai.Venues.EstimatedFundingRate{} = estimated_funding_rate | _] = estimated_funding_rates
        assert estimated_funding_rate.venue == @venue.id
        assert estimated_funding_rate.venue_product_symbol != nil
        assert estimated_funding_rate.product_symbol != nil
        assert %DateTime{} = estimated_funding_rate.next_time
        assert %Decimal{} = estimated_funding_rate.next_rate
      end
    end
  end)

  def setup_adapter(:mock) do
    now = Timex.now
    Tai.TestSupport.Mocks.Responses.EstimatedFundingRates.for_venue(
      :mock,
      [
        %{
          venue_product_symbol: "BTC-USD",
          product_symbol: :btc_usd,
          next_time: now,
          next_rate: Decimal.new("0.001")
        },
        %{
          venue_product_symbol: "LTC-USD",
          product_symbol: :ltc_usd,
          next_time: now,
          next_rate: Decimal.new("0.002")
        }
      ]
    )
  end

  def setup_adapter(_), do: nil
end
